#
# Cookbook Name:: monit
# Recipe:: default
#
# Copyright 2008, Engine Yard, Inc.
#
# All rights reserved - Do Not Redistribute
#

monit_version = node.engineyard.metadata("monit_version", node['monit']['version'])
Chef::Log.info "Monit Version: #{monit_version}"

ey_cloud_report "monit" do
  message "processing monit"
end

package 'monit' do
  version monit_version
  action :install
end

service 'monit' do
  provider Chef::Provider::Service::Systemd
  action :nothing
end

template "/etc/monitrc" do
  owner "root"
  group "root"
  mode 0700
  source 'monitrc.erb'
  action :create
end

bash "migrate-monit.d-dir" do
  code %Q{
    mv /etc/monit.d /data/
    ln -nfs /data/monit.d /etc/monit.d
  }

  not_if 'file /etc/monit.d | grep "symbolic link"'
end

directory "/data/monit.d" do
  owner "root"
  group "root"
  mode 0755
end

template "/etc/monit.d/alerts.monitrc" do
  owner "root"
  group "root"
  mode 0700
  source 'alerts.monitrc.erb'
  action :create_if_missing
end

template "/usr/local/bin/monit" do
  owner "root"
  group "root"
  mode 0700
  source 'monit.erb'
  variables({
      :nofile => 16384
  })
  action :create_if_missing
end

execute "touch monitrc" do
  command "touch /etc/monit.d/ey.monitrc"
end

cookbook_file "/etc/systemd/system/monit.service" do
  owner "root"
  group "root"
  mode 0700
  source "monit.service"
  notifies :enable, "service[monit]", :immediately
  notifies :restart, "service[monit]", :immediately
end

=begin
# TODOv6 why does restart-monit pkill -9 rackup and mongrel_rails
execute "restart-monit" do
  apps = node['dna']['applications'].map{|app, data| data['type'] }
  cmd = []
  apps.each do |app|
    case app
    when 'rails'
      cmd << "pkill -9 mongrel_rails"
    when 'rack'
      cmd << "pkill -9 rackup"
    end
  end
  cmd.uniq!
  command %Q{ #{cmd.join(' && ')} || [[ $? == 1 ]]}
  command %Q{ pkill -9 monit || [[ $? == 1 ]]}
  action :nothing
end

# TODOv6 is this needed?
execute "monit quit" do
  action :nothing
  notifies :restart, 'service[monit]'
end
=end
