#
# Cookbook Name:: puma
# Recipe:: default
#
# Copyright 2011, Engine Yard, Inc.
#
# All rights reserved - Do Not Redistribute
#

ey_cloud_report "puma" do
  message "processing puma"
end

base_port     = 8200
stepping      = 200
app_base_port = base_port
ports = []

# Total workers are based on CPU counts on target instance, with a minimum of 1 worker per app
workers = [(1.0*node['cpu']['total']/node['dna']['applications'].size).round,1].max
# Adding puma restart sleep timeout
sleep_timeout = node['puma']['sleep_timeout']

node.engineyard.apps.each_with_index do |app,index|
  app_base_port = base_port + ( stepping * index )
  app_path      = "/data/#{app.name}"
  deploy_file   = "#{app_path}/current/REVISION"
  log_file      = "#{app_path}/shared/log/puma.log"
  ssh_username  = node.engineyard.environment.ssh_username
  framework_env = node['dna']['environment']['framework_env']
  solo = node['dna']['instance_role'] == 'solo'

  ports = (app_base_port...(app_base_port+workers)).to_a

  directory "#{app.name} nginx app directory for puma" do
    path "/data/nginx/servers/#{app.name}"
    owner node.engineyard.environment.ssh_username
    group node.engineyard.environment.ssh_username
    mode 0775
  end

  file "#{app.name} custom.conf for puma" do
    path "/data/nginx/servers/#{app.name}/custom.conf"
    action :create_if_missing
    owner node.engineyard.environment.ssh_username
    group node.engineyard.environment.ssh_username
    mode 0644
  end

  # HAX for SD-4650
  # Remove it when awsm stops using dnapi to generate the dna and allows configure ports
  meta = node.engineyard.apps.detect {|a| a.metadata?(:nginx_http_port) }
  nginx_http_port = ( meta and meta.metadata?(:nginx_http_port) ) || 8081

  managed_template "#{app.name}.conf for puma" do
    path "/data/nginx/servers/#{app.name}.conf"
    owner node.engineyard.environment.ssh_username
    group node.engineyard.environment.ssh_username
    mode 0644
    source "nginx_app.conf.erb"
    variables({
      :app_name => app.name,
      :vhost => app.vhosts.first,
      :port => nginx_http_port,
      :upstream_ports => ports,
      :framework_env => node.engineyard.environment.framework_env
    })
    notifies node['nginx'][:action], resources(:service => "nginx"), :delayed
  end

  directory "/var/run/engineyard/#{app.name}" do
    owner ssh_username
    group ssh_username
    mode 0755
    recursive true
  end

  template "/data/#{app.name}/shared/config/env" do
    source "env.erb"
    backup 0
    owner ssh_username
    group ssh_username
    mode 0755
    cookbook 'puma'
    variables(:app_name      => app.name,
              :user          => ssh_username,
              :deploy_file   => deploy_file,
              :framework_env => framework_env,
              :baseport      => app_base_port,
              :workers       => workers,
              :threads       => '' # Uses default of 0:16
             )
  end

  template "/engineyard/bin/app_#{app.name}" do
    source  'app_control.erb'
    owner   ssh_username
    group   ssh_username
    mode    0755
    backup  0
    cookbook  'puma'

    variables(:app_name      => app.name,
              :app_dir       => "#{app_path}/current",
              :deploy_file   => deploy_file,
              :shared_path   => "#{app_path}/shared",
              :ports         => ports,
              :framework_env => framework_env,
              :jruby         => node.engineyard.environment.jruby?),
              :sleep_timeout => sleep_timeout)

  end

  logrotate "puma_#{app.name}" do
    files log_file
    copy_then_truncate
  end

  # :app_memory_limit is no longer used but is checked here and overridden when :worker_memory_size is available
  depreciated_memory_limit = metadata_app_get_with_default(app.name, :app_memory_limit, "255.0")
  # See https://support.cloud.engineyard.com/entries/23852283-Worker-Allocation-on-Engine-Yard-Cloud for more details
  memory_limit = metadata_app_get_with_default(app.name, :worker_memory_size, depreciated_memory_limit)

  managed_template "/etc/monit.d/puma_#{app.name}.monitrc" do
    source "puma.monitrc.erb"
    owner "root"
    group "root"
    mode 0666
    backup 0
    cookbook  'puma'
    variables(:app => app.name,
              :app_memory_limit => memory_limit,
              :username => ssh_username,
              :ports => ports)
    notifies :run, "execute[reload-monit]"
  end

end
