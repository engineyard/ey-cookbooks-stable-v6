#
# Cookbook Name:: ey-cron
# Recipe:: default
#
# Copyright 2009, Engine Yard, Inc.
#
# All rights reserved - Do Not Redistribute
#

ey_cloud_report "cron" do
  message "processing crontabs"
  only_if node['dna']['crons'].empty?
end

cron_header = ""
if node.engineyard.environment.ruby?
  cron_header = <<-CRON
# begin-ey-cron-header This is a delimiter. DO NOT DELETE

PATH=/opt/rubies/ruby-#{node['ruby']['version']}/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
RAILS_ENV="#{node.engineyard.environment['framework_env']}"
RACK_ENV="#{node.engineyard.environment['framework_env']}"
# end-ey-cron-header This is a delimiter. DO NOT DELETE
  CRON
elsif node.engineyard.environment['stack_name'].match /nginx_fpm/
  cron_header = <<-CRON
# begin-ey-cron-header This is a delimiter. DO NOT DELETE

PHP_ENV="#{node.engineyard.environment['framework_env']}"
# end-ey-cron-header This is a delimiter. DO NOT DELETE
  CRON
end

file "/tmp/cron_header" do
  content cron_header
end

cron_files = ["/var/spool/cron/crontabs/root", "/var/spool/cron/crontabs/#{node['owner_name']}"]
cron_files.each do |cron_file|
  if !File.exist?(cron_file)
    file cron_file do
      content "#\n#\n#\n"
    end
  end
end

execute "add environment variables to cron" do
  command "sed -i '/begin-ey-cron-header/, /'end-ey-cron-header'/d' /var/spool/cron/crontabs/root && sed -i '3r /tmp/cron_header' /var/spool/cron/crontabs/root"
end

# Make same changes to user's cron
execute "add environment variables to user's cron" do
  command "sed -i '/begin-ey-cron-header/, /'end-ey-cron-header'/d' /var/spool/cron/crontabs/#{node['owner_name']} && sed -i '3r /tmp/cron_header' /var/spool/cron/crontabs/#{node['owner_name']}"
end

unless 'app' == node['dna']['instance_role']
  cron "ey-snapshots" do
    minute   node['snapshot_minute']
    hour     node['snapshot_hour']
    day      '*'
    month    '*'
    weekday  '*'
    command  "ey-snapshots --snapshot >> /var/log/ey-snapshots.log"
    not_if { node[':backup_window'].to_s == '0' }
  end
end

directory "/var/spool/cron" do
  group "crontab"
end

include_recipe 'ey-cron::ui'

include_recipe 'ntp::cronjobs'

directory "/etc/systemd/system/cron.service.d" do
  owner "root"
  group "root"
  mode 0755
  recursive true
end

file "/var/spool/cron/crontabs/#{node['owner_name']}" do
    owner "#{node['owner_name']}"
    group "crontab"
end

cookbook_file "/etc/systemd/system/cron.service.d/override.conf" do
  source "cron_override.conf"
  owner "root"
  group "root"
  mode 0644
  notifies :run, "execute[reload-systemd]", :delayed
end
