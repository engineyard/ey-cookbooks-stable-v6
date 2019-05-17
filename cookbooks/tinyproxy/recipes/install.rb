# Change app_name based on your application name
app_name = node['tinyproxy']['app_name']
proxy_port = node['tinyproxy']['port']
config_file = "/data/#{app_name}/shared/tinyproxy/tinyproxy.conf"
pid_file = "/data/#{app_name}/shared/tinyproxy/tinyproxy.pid"

if (node['tinyproxy']['install_type'] == 'APP_MASTER' && node['dna']['instance_role'] == 'app_master' ||
     node['tinyproxy']['install_type']== 'NAMED_UTIL' && node['dna']['instance_role'] == 'util' && node['dna']['name'] == node['tinyproxy']['utility_name'])

  # Install the tinyproxy package
  package "tinyproxy" do
    version node['tinyproxy']['version']
    action :install
  end

  # Create the tinyproxy directory
  directory "/data/#{app_name}/shared/tinyproxy" do
    owner 'deploy'
    group 'deploy'
    mode 0777
    recursive true
    action :create
  end

  # Create the tinyproxy config file
  template config_file do
    owner 'deploy'
    group 'deploy'
    mode 0644
    source 'tinyproxy.conf.erb'
    variables({
      :app_name => app_name,
      :port => proxy_port
    })
  end

  # Ensure everything in the tinyproxy directory is owned by deploy
  execute "chown tinyproxy directory" do
    command "chown -R deploy:deploy /data/#{app_name}/shared/tinyproxy"
    action :run
  end

  # Run tinyproxy from monit
  template '/data/monit.d/tinyproxy.monitrc' do
    owner 'root'
    group 'root'
    mode 0644
    source 'tinyproxy.monitrc.erb'
    variables({
      :pid_file => pid_file,
      :config_file => config_file
    })
  end
else
  # For non-tinyproxy instances, delete any tinyproxy.monitrc
  # that may have been carried over from a snapshot
  cleanup_tinyproxy_monitrc
end

execute 'monit reload' do
  action :run
end
