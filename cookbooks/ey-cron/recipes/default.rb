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

cron_header = <<-CRON
# begin-ey-cron-header This is a delimeter. DO NOT DELETE

# The cron jobs from the Engine Yard UI can be found on /etc/cron.d/ey-cron-jobs

PATH=/opt/rubies/ruby-#{node['ruby']['version']}/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
RAILS_ENV="#{node.engineyard.environment['framework_env']}"
RACK_ENV="#{node.engineyard.environment['framework_env']}"
# end-ey-cron-header This is a delimeter. DO NOT DELETE
CRON

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

if crontab_instance?(node)
  cron_text = []
  cron_text << <<-CRON
# These are the cron jobs from the Engine Yard UI

PATH=/opt/rubies/ruby-#{node['ruby']['version']}/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
RAILS_ENV="#{node.engineyard.environment['framework_env']}"
RACK_ENV="#{node.engineyard.environment['framework_env']}"
CRON
  (node['dna']['crons']||[]).each do |c|
    cron_text << "# #{c['name']}"
    cron_text << "#{c['minute']} #{c['hour']} #{c['day']} #{c['month']} #{c['weekday']} #{c['user']} #{c['command']}"
  end
  cron_text << ""
  file "/etc/cron.d/ey-cron-jobs" do
    content cron_text.join("\n")
    owner "root"
    group "root"
    mode 0644
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
