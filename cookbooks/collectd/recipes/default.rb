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

include_recipe 'collectd::httpd'

template "/engineyard/bin/ey-alert.rb" do
  owner 'root'
  group 'root'
  mode 0755
  source "ey-alert.erb"
  variables({
    :url => node['dna']['reporting_url']
  })
end

package 'collectd' do
  notifies :stop, "service[collectd]", :immediately
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

case node.engineyard.environment['db_stack_name']
when /^mysql\d+/
  short_version = node['mysql']['short_version']
when /^postgres\d+/
  short_version = node['postgresql']['short_version']
when "no_db"
  has_db = false
end

include_recipe "collectd::perl"

# Handle duplicated RRD data directories
# 1. If the instance RRD data directory does not exist, but some others,
#    copy the directory with the latest mtime to the instance RRD data directory
# 2. Remove all other RRD data directories
instance = node.dna.engineyard.environment.instances.detect { |i| i['id'] == node.dna.engineyard['this'] }
private_hostname=instance["private_hostname"]
rrd_basedir = File.expand_path('/var/lib/collectd/rrd')
rrd_datadir = File.expand_path(File.join(rrd_basedir, private_hostname))
existing_rrd_datadirs = Dir[File.join(rrd_basedir, '*')]
  .map { |f| [f, File.mtime(f)] }
  .sort_by { |fm| fm[1] }
  .map { |fm| fm[0] }
if existing_rrd_datadirs.length == 0
  latest_rrd_datadir = nil
else
  latest_rrd_datadir = File.expand_path(existing_rrd_datadirs[-1])
end
if !File.exist?(rrd_datadir) and latest_rrd_datadir
  # copy the dir with the latest mtime to rrd_datadir
  bash "copy the latest modified RRD data dir #{latest_rrd_datadir} to the new RRD data dir #{rrd_datadir}" do
    code <<-EOC
    cp -a #{latest_rrd_datadir} #{rrd_datadir}
    EOC
  end
end
# delete everything other than rrd_datadir
existing_rrd_datadirs.each do |dir|
  if File.expand_path(dir) != rrd_datadir
    directory dir do
      recursive true
      action :delete
    end
  end
end

memcached = node['memcached'] && node['memcached']['perform_install']
db_type = node.engineyard.environment['db_stack_name']
is_postgres_db = db_type.match(/^(postgres\d+)/)
is_mysql_db = db_type.match(/^(mysql\d+)/)
managed_template "/etc/engineyard/collectd.conf" do
  owner 'root'
  group 'root'
  mode 0644
  source "collectd.conf.erb"
  variables(
    lazy {
      {
        :db_type         => db_type,
        :has_db          => has_db,
        :is_postgres_db  => is_postgres_db,
        :is_mysql_db     => is_mysql_db,
        :databases       => has_db ? node.engineyard.environment['apps'].map {|a| a['database_name']} : [],
        :db_slaves       => node.dna['db_slaves'],
        :role            => node.dna['instance_role'],
        :memcached       => memcached,
        :user            => node["owner_name"],
        :alert_script    => "/engineyard/bin/ey-alert.rb",
        :load_warning    => node['collectd']['load']['warning'],
        :load_failure    => node['collectd']['load']['failure'],
        :swap_thresholds => SwapThresholds.new,
        :short_version   => short_version,
        :disk_thresholds => DiskThresholds.new
      }
    }
  )
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

cookbook_file "/etc/engineyard/mounts_ro_ignore" do
  source "mounts_ro_ignore"
  owner node["owner_name"]
  group node["owner_name"]
  mode 0755
  not_if { File.exist?('/etc/engineyard/mounts_ro_ignore')}
end

cookbook_file "/etc/systemd/system/collectd.service" do
  source "collectd.service"
  owner "root"
  group "root"
  mode 0644
  notifies :run, "execute[reload-systemd]", :immediately
  notifies :enable, "service[collectd]", :immediately
  notifies :restart, "service[collectd]", :immediately
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
