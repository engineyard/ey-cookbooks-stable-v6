#
# Cookbook Name:: redis
# Recipe:: default
#
# Download and install redis if one of the following is true:
# - the redis base directory does not exist
# - force_upgrade == true
#
# Create the redis basedir if the redis basedir does not exist
#

redis_version = (node['redis']['version'] || '4.0.9') # The Ubuntu 18.04 version is 4.0.9
# Deduce the redis_config_file_version from the full Redis version string
#   1. remove possible -RCx in version
#   2. split into major, minor, and (optionally) patch version components
#   3. use major.minor as redis_config_file_version
version_regex = /(\d+)\.(\d+)(\.\d+)?(-rc\d+)?/i
if vmatch = version_regex.match(redis_version)
  redis_config_file_version = "#{vmatch[1]}.#{vmatch[2]}"
else
  Chef::Log.fatal "Invalid Redis version."
  exit(1)
end
redis_base_directory = node['redis']['basedir']

run_installer = !FileTest.exists?(redis_base_directory) || node['redis']['force_upgrade']

if node['redis']['install_from_source']
  redis_bin_path = '/usr/local/bin/redis-server'
else
  redis_bin_path = '/usr/bin/redis-server'
end

# check if redis-server exists
run_installer = not File.exist?(redis_bin_path)

if node['redis']['is_redis_instance']

  sysctl "Enable Overcommit Memory" do
    variables 'vm.overcommit_memory' => 1
  end

  execute "reload sysctl before starting redis" do
    command "sysctl -p"
  end

  thp_filename = '/sys/kernel/mm/transparent_hugepage/enabled'
  transparent_hugepage_command = "echo never > #{thp_filename}"
  if ::File.exists?(thp_filename)
    execute 'disable transparent huge pages when present' do
      command transparent_hugepage_command
    end

    execute "set #{thp_filename} on boot" do
      command "sed -i '1a #{transparent_hugepage_command}' /etc/rc.local"
      not_if "grep -e '#{transparent_hugepage_command}' /etc/rc.local"
    end
  end

  execute "create redis user" do
    command "adduser --system --home /var/lib/redis --group redis"
    not_if "getent passwd redis"
  end

  [redis_base_directory, "/var/run/redis", "/var/lib/redis", "/etc/redis"].each do |dir|
    directory dir do
      owner 'redis'
      group 'redis'
      mode 0755
      recursive true
      action :create
    end
  end

  redis_config_variables = {
    'basedir' => node['redis']['basedir'],
    'basename' => node['redis']['basename'],
    'logfile' => node['redis']['logfile'],
    'loglevel' => node['redis']['loglevel'],
    'port'  => node['redis']['port'],
    'saveperiod' => node['redis']['saveperiod'],
    'timeout' => node['redis']['timeout'],
    'databases' => node['redis']['databases'],
    'rdbcompression' => node['redis']['rdbcompression'],
    'rdb_filename' => node['redis']['rdb_filename'],
    'hz' => node['redis']['hz']
  }
  if ((node['dna']['instance_role'] != 'solo') &&
      !node['redis']['slave_name'].to_s.empty? &&
      (node['dna']['name'] == node['redis']['slave_name']))
    redis_config_template = "redis-#{redis_config_file_version}-slave.conf.erb"

    # TODO: Move this to a function
    instances = node['dna']['engineyard']['environment']['instances']
    redis_master_instance = instances.find{|i| i['name'] == node['redis']['utility_name']}

    if redis_master_instance.nil?
      raise "Redis utility instance named '#{node['redis']['utility_name']}' doesn't exist"
    end

    redis_config_variables['master_ip'] = redis_master_instance['private_hostname']
  else
    redis_config_template = "redis-#{redis_config_file_version}.conf.erb"
  end

  redis_config_path = "/etc/redis/redis.conf"
  template redis_config_path do
    owner 'redis'
    group 'redis'
    mode 0644
    source redis_config_template
    variables redis_config_variables
  end

  service "redis-server" do
    provider Chef::Provider::Service::Systemd
    action :nothing
  end

  template "/etc/systemd/system/redis-server.service" do
    owner 'root'
    group 'root'
    mode 0644
    source "redis-server.service.erb"
    variables({
      redis_bin_path: redis_bin_path,
      redis_config_path: redis_config_path,
      basedir: node['redis']['basedir'],
    })
    notifies :run, "execute[reload-systemd]", :immediately
    notifies :enable, "service[redis-server]", :immediately
    notifies :restart, "service[redis-server]" # restart after installing redis
  end

  if run_installer
    if node['redis']['install_from_source']
      include_recipe 'redis::install_from_source'
    else
      include_recipe 'redis::install_from_package'
    end
  end

  service "start redis-server" do
    service_name "redis-server"
    provider Chef::Provider::Service::Systemd
    action :start
  end
end
