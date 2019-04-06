#
# Cookbook Name:: cron
# Recipe:: default
#

# Find all cron jobs specified in attributes/cron.rb where current node name matches instance_name
named_crons = node[:custom_crons].find_all {|c| c[:instance_name] == node['dna']['name'] }

# Find all cron jobs for utility instances
util_crons = node[:custom_crons].find_all {|c| c[:instance_name] == 'util' }

# Find all cron jobs for app master only
app_master_crons = node[:custom_crons].find_all {|c| c[:instance_name] == 'app_master' }

# Find all cron jobs for solo only
solo_crons = node[:custom_crons].find_all {|c| c[:instance_name] == 'solo' }

# Find all cron jobs for application instances
app_crons = node[:custom_crons].find_all {|c| c[:instance_name] == 'app' }

# Find all cron jobs for ALL instances
all_crons = node[:custom_crons].find_all {|c| c[:instance_name] == 'all' }

# Find all cron jobs for Database instances
db_crons = node[:custom_crons].find_all {|c| c[:instance_name] == 'db' }

crons = all_crons + named_crons


if node['dna']['instance_role'] == 'util'
    crons = crons + util_crons
end

if  node['dna']['instance_role'] == 'app_master'
    crons = crons + app_master_crons
end

if  node['dna']['instance_role'] == 'solo'
    crons = crons + solo_crons
end

if node['dna']['instance_role'] == 'app' || node['dna']['instance_role'] == 'app_master'
    crons = crons + app_crons
end

if node['dna']['instance_role'] == 'db_master' || node['dna']['instance_role'] == 'db_slave'
    crons = crons + db_crons
end

# get the existing cron jobs created by this cron recipe
existing_crons_command = Mixlib::ShellOut.new("grep -E -o '\# Chef Name: custom_cron_(.*)' /var/spool/cron/crontabs/#{node['owner_name']}")
existing_crons_command.run_command
existing_cron_names = existing_crons_command.stdout
existing_crons = []

# get the existing cron names without the prefix custom_cron_
existing_cron_names.each_line do |line|
  existing_crons << line.chomp.gsub(/\# Chef Name: custom_cron_/,'')
end
Chef::Log.debug "current custom cron jobs #{existing_crons.inspect}"

# get the cron jobs that don't exist on the custom-cron attributes
deleted_crons = existing_crons - crons.map{|c| c[:name]}
Chef::Log.debug "deleted custom cron jobs #{deleted_crons.inspect}"
deleted_crons.each do |deleted_cron|
  cron "custom_cron_#{deleted_cron}" do
    user node['owner_name']
    action :delete
  end
end

# Add custom_cron_ prefix to the name
crons.each do |cron|
  custom_cron_name = "custom_cron_#{cron[:name]}"
  cron custom_cron_name do
    user     node['owner_name']
    action   :create
    minute   cron[:time].split[0]
    hour     cron[:time].split[1]
    day      cron[:time].split[2]
    month    cron[:time].split[3]
    weekday  cron[:time].split[4]
    command  cron[:command]
  end
end


