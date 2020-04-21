#
# Cookbook Name:: passenger5
# Recipe:: install
#

recipe = self

# Notify dashboard
ey_cloud_report "passenger5" do
  message "Processing Passenger 5"
end

# Install gems required by Passenger standalone
ruby_block "gems to install" do
  block do
    system("gem install daemon_controller rack:1.6.4")
  end
end

gem_package 'passenger' do
  version node['passenger5']['version']
  action :install
end

# Grab version, ssh user, rails_env and port
version       = node['passenger5']['version']
ssh_username  = node['owner_name']
framework_env = node['dna']['environment']['framework_env']
port          = node['passenger5']['port']

# Write out the advanced configuration file
# From the Passenger Standalone documentation:
# Please note that changes to this file only last until you reinstall or upgrade Phusion Passenger.
# We are currently working on a mechanism for permanently editing the configuration file.
# template "/opt/passenger-server-5.0.29/resources/templates/standalone/config.erb" do
#   owner ssh_username
#   group ssh_username
#   mode 0644
#   source "config.erb"
#   action :create
# end
base_port = node['passenger5']['port'].to_i
stepping = 200
app_base_port = base_port

node.engineyard.apps.each_with_index do |app,index|
  app_path      = "/data/#{app.name}"
  app_base_port = base_port + ( stepping * index )
  log_file      = "#{app_path}/shared/log/passenger.#{app_base_port}.log"

  # Render app control script, this script calls the passenger enterprise binaries using the full path
  template "/engineyard/bin/app_#{app.name}" do
    source  'app_control.erb'
    owner   ssh_username
    group   ssh_username
    mode    0755
    backup  0
    variables(
      lazy {
        {
          :user         => ssh_username,
          :app_name     => app.name,
          :version      => version,
          :port         => app_base_port,
          :worker_count => recipe.get_pool_size,
          :rails_env    => framework_env
        }
      }
    )
  end

  # Setup log rotate for passenger.log
  logrotate "passenger5_#{app.name}" do
    files log_file
    copy_then_truncate
  end

  # Render monitrc file to watch standalone passenger
  template "/etc/monit.d/passenger5_#{app.name}.monitrc" do
    source "passenger5.monitrc.erb"
    owner "root"
    group "root"
    mode 0666
    backup 0
    variables(:app              => app.name,
              :app_memory_limit => app_server_get_worker_memory_size(app),
              :username         => ssh_username,
              :port             => app_base_port,
              :version          => version)
    notifies :run, "execute[reload-monit]", :delayed
  end
end

# Render passenger_monitor script
cookbook_file "/engineyard/bin/passenger_monitor" do
  source "passenger_monitor"
  owner node['owner_name']
  group node['owner_name']
  mode "0655"
  backup 0
end
