#
# Cookbook Name:: collectd
# Recipe:: default
#
# Copyright 2008, Engine Yard, Inc.
#
# All rights reserved - Do Not Redistribute
#

ey_cloud_report "collectd" do
  message 'processing performance monitoring'
end

=begin TODOv6
# Update rrdtool-binding to latest available
# - updates net-analyzer/rrdtool as well
package 'dev-ruby/rrdtool-bindings' do
  action :upgrade
end

=end
include_recipe 'collectd::httpd'

template "/engineyard/bin/ey-alert.rb" do
  owner 'root'
  group 'root'
  mode 0755
  source "ey-alert.erb"
  variables({
    :url => node['dna'][:reporting_url]
  })
end

package 'collectd' do
 version node['collectd']['version']
end

service 'collectd' do
  provider Chef::Provider::Service::Systemd
  action :nothing
end

cookbook_file "/engineyard/bin/collectd_nanny" do
  owner 'root'
  group 'root'
  mode 0755
  source 'collectd_nanny'
end

cron 'hourly collectd check' do
  minute '5'
  hour '0-2,4-23'
  day '*'
  month '*'
  weekday '*'
  command '/engineyard/bin/collectd_nanny'
end

cron 'daily collectd check' do
  minute '5'
  hour '3'
  day '*'
  month '*'
  weekday '*'
  command '/engineyard/bin/collectd_nanny daily'
end

has_db = ['solo','db_master','db_slave'].include?(node['dna']['instance_role'])

=begin TODOv6
case node.engineyard.environment['db_stack_name']
when /mysql/
  cookbook_file "/usr/lib/collectd/mysql.so" do
    source "#{node['kernel']['machine']}/#{node['mysql']['short_version']}/mysql.so"
    #source "#{node['kernel']['machine']}/5.7/mysql.so"
    cookbook "mysql"
    mode 0755
    backup 0
  end
  short_version=node['mysql']['short_version']
when /postgres/
  short_version=node['postgresql']['short_version']
when "no_db"
  has_db=false
end
=end

include_recipe "collectd::perl"

memcached = node['memcached'] && node['memcached']['perform_install']
managed_template "/etc/engineyard/collectd.conf" do
  owner 'root'
  group 'root'
  mode 0644
  source "collectd.conf.erb"
  variables({
    :db_type => node.engineyard.environment['db_stack_name'],
    :databases => has_db ? node.engineyard.environment['apps'].map {|a| a['database_name']} : [],
    :has_db => has_db,
    :db_slaves => node['dna']['db_slaves'],
    :role => node['dna']['instance_role'],
    :memcached => memcached,
    :user => node["owner_name"],
    :alert_script => "/engineyard/bin/ey-alert.rb",
    :load_warning => node['collectd']['load']['warning'],
    :load_failure => node['collectd']['load']['failure'],
    :swap_critical_total => node['swap_critical_total'],
    :swap_warning_total => node['swap_warning_total'],
    :short_version => 'TODOv6', #short_version,
    :disk_thresholds => DiskThresholds.new
  })
  notifies :restart, "service[collectd]", :delayed
end

cookbook_file "/engineyard/bin/check_readonly.sh" do
  source "check_readonly.sh"
  owner node["owner_name"]
  group node["owner_name"]
  backup 0
  mode 0755
end

cookbook_file "/engineyard/bin/check_health_for" do
  source "check_health_for"
  owner node["owner_name"]
  group node["owner_name"]
  backup 0
  mode 0755
end

cookbook_file "/etc/engineyard/fs_type_check_ignore" do
  source "fs_type_ignore_defaults"
  owner node["owner_name"]
  group node["owner_name"]
  mode 0755
  not_if { File.exist?('/etc/engineyard/fs_type_check_ignore')}
end

cookbook_file "/etc/systemd/system/collectd.service" do
  source "collectd.service"
  owner "root"
  group "root"
  mode 0644
  notifies :run, "execute[reload-systemd]", :delayed
  notifies :enable, "service[collectd]", :delayed
  notifies :restart, "service[collectd]", :delayed
end

# This is the graphs app that awsm proxies
execute "install-graphs-app" do
  command %Q{
    curl https://ey-ec2.s3.amazonaws.com/#{node['collectd']['graph']['graphs_tarball_name']} -O &&
    tar xvzf #{node['collectd']['graph']['graphs_tarball_name']} &&
    rm -rf #{node['collectd']['graph']['path']} &&
    mkdir -p #{node['collectd']['graph']['path']} &&
    cp -R graphs/* #{node['collectd']['graph']['path']} &&
    chmod +x #{node['collectd']['graph']['path']}/bin/* &&
    rm -rf graphs*
  }
  not_if { File.exists?(node['collectd']['graph']['version_file']) and
    File.read(node['collectd']['graph']['version_file']).chomp.sub('v','').to_i == node['collectd']['graph']['version']
  }
end

# The real one is /etc/engineyard/collectd.conf
# leaving the default one in place is confusing
execute "cleanup_original_collectd_conf" do
  command %Q{
    rm /etc/collectd/collectd.conf
  }
  only_if { File.exist?('/etc/collectd/collectd.conf') }
end
