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

execute "clearing old crons" do
  command "crontab -r; crontab -r -u #{node['owner_name']}; true"
end

update_file "/tmp/cron_update_header" do
  action :rewrite

  body <<-CRON
PATH=/opt/rubies/ruby-#{node['ruby']['version']}/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
RAILS_ENV="#{node.engineyard.environment['framework_env']}"
RACK_ENV="#{node.engineyard.environment['framework_env']}"
PHP_ENV="#{node.engineyard.environment['framework_env']}"
CRON
end

execute "add environment variables to cron" do
  command "crontab /tmp/cron_update_header"
end

# Make same changes to user's cron
execute "add environment variables to user's cron" do
  command "crontab -u #{node['owner_name']} /tmp/cron_update_header"
end

file "remote /tmp/cron_update_header" do
  path "/tmp/cron_update_header"
  action :delete
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

if crontab_instance?(node)
  (node['dna']['crons']||[]).each do |c|
    cron c['name'] do
      minute   c['minute']
      hour     c['hour']
      day      c['day']
      month    c['month']
      weekday  c['weekday']
      command  c['command']
      user     c['user']
    end
  end
end

# This and the remote_file for cron_nanny go together
# Cron touches a file every minute
cron 'touch cron-check' do
  minute  '*'
  hour    '*'
  day     '*'
  month   '*'
  weekday '*'
  command 'touch /tmp/cron-check'
end

# Cron nanny attempts to DTRT when cron isn't updating
# the file every minute
cookbook_file '/engineyard/bin/cron_nanny' do
  owner 'root'
  group 'root'
  mode 0755
  source 'cron_nanny'
end

=begin TODOv6
execute "Ensure that cron_nanny is restarted by init with the latest version" do
  command %Q~
  for proc in /proc/[0-9]*
  do
    _pid="${proc##*/}"
    (( _pid > 1 )) && [[ ${_pid} != $self ]]|| continue

    if command grep -q '/engineyard/bin/[c]ron_nanny' ${proc}/cmdline
    then kill -9 ${_pid} ; fi
  done
  telinit q
  ~
end

include_recipe 'ntp::cronjobs'
=end
