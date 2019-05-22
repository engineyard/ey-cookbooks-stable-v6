class Chef::Recipe
  include PhpHelpers
end

# Report to Cloud dashboard
ey_cloud_report "processing php#{node["php"]["minor_version"]}" do
  message "processing php - php-fpm #{node["php"]["minor_version"]}"
end

# Overwrite default php config
directory "/etc/php/#{node["php"]["minor_version"]}/fpm" do
  owner "root"
  group "root"
  recursive true
  mode "0755"
  action :create
end

cookbook_file "/etc/php/#{node["php"]["minor_version"]}/fpm/php.ini" do
  source "php.ini"
  owner "root"
  group "root"
  mode "0755"
  backup 0
end

# create directory for fpm logs
directory "/var/log/engineyard/php-fpm" do
  owner node["owner_name"]
  group node["owner_name"]
  mode "0755"
  action :create
end

# create error log for fpm
file "/var/log/engineyard/php-fpm/error.log" do
  owner node["owner_name"]
  group node["owner_name"]
  mode "0644"
  action :create_if_missing
end

# create directory for unix socket(s)
directory "/var/run/engineyard" do
  owner node["owner_name"]
  group node["owner_name"]
  recursive true
  mode "0755"
  action :create
end


=begin
bash 'eselect php and restart via monit' do
  code <<-EOH
    eselect php set fpm php#{node["php"]["minor_version"]}
    EOH
  not_if "php-fpm -v | grep PHP | grep #{node['php']['version']}"
  notifies :run, 'execute[monit_restart_fpm]'
end
=end

# get all applications with type PHP
apps = node['dna']['applications'].select{ |app, data| data['recipes'].detect{ |r| r == 'php' } }
# collect just the app names
app_names = apps.collect{ |app, data| app }

# generate global fpm config
template "/etc/php-fpm.conf" do
  owner node["owner_name"]
  group node["owner_name"]
  mode "0644"
  source "fpm-global.conf.erb"
  variables({
    :apps => app_names
  })
#  notifies :restart, resources(:service => "php-fpm"), :delayed
end

# Can't access get_fpm_coount inside block
app_fpm_count = (get_fpm_count / node['dna']['applications'].size)
app_fpm_count = 1 unless app_fpm_count >= 1

ssh_username = node.engineyard.environment.ssh_username
# generate an fpm pool for each php app
app_names.each do |app_name|
  cookbook_file "/data/#{app_name}/shared/config/env.custom" do
    source "env.custom"
    owner node.engineyard.environment.ssh_username
    group node.engineyard.environment.ssh_username
    mode 0755
    backup 0
    not_if { FileTest.exists?("/data/#{app_name}/shared/config/env.custom") }
  end

  mc_hostnames = node.engineyard.environment.instances.map{|i| i['private_hostname'] if i['role'][/^app|solo/]}.compact.map {|i| "#{i}:11211"}

  template "/data/#{app_name}/shared/config/fpm-pool.conf" do
    owner node["owner_name"]
    group node["owner_name"]
    mode 0644
    source "fpm-pool.conf.erb"
    variables({
      :app_name => app_name,
      :php_env => node['dna']['environment']['framework_env'],
      :user => node["owner_name"],
      :dbuser => node.engineyard.environment.apps.detect {|app| app[:name] == app_name}.database_username,
      :dbpass => node.engineyard.environment.apps.detect {|app| app[:name] == app_name}.database_password,
      :dbhost => node['dna']['db_host'],
      :dbreplicas => node['dna']['db_slaves'].join(':'),
      :max_children => app_fpm_count,
      :memcache_hostnames => mc_hostnames.join(',')
    })

  end
end

template "/etc/systemd/system/php#{node["php"]["minor_version"]}-fpm.service" do
  source "php-fpm.service.erb"
  variables({
    version: node["php"]["minor_version"],
    user: node.engineyard.environment.ssh_username,
    group: node.engineyard.environment.ssh_username
  })
  notifies :run, "execute[reload-systemd]", :immediately
end

other_versions = node['php']['known_versions'].reject{ |version| version == node['php']['minor_version'] }
other_versions.each do |version|
  execute "stop php #{version} if installed" do
    command "systemctl stop php#{version}-fpm"
    ignore_failure true
    only_if { File.exist?("/etc/systemd/system/php#{version}-fpm.service") }
  end
end
package "php#{node["php"]["minor_version"]}-fpm"

service "php#{node["php"]["minor_version"]}-fpm" do
  action :start
end

# get all applications with type PHP
apps = node['dna']['applications'].select{ |app, data| data['recipes'].detect{ |r| r == 'php' } }
# collect just the app names
app_names = apps.collect{ |app, data| app }

app_names.each do |app|
  template "/engineyard/bin/app_#{app}" do
    source "app_control.erb"
    owner   ssh_username
    group   ssh_username
    mode    0755
    variables({
      version: node["php"]["minor_version"]
    })
  end

  # Change ownership of app slowlog if set to root
  check_fpm_log_owner(app)
end

# cookbooks/php/libraries/php_helpers.rb
restart_fpm
