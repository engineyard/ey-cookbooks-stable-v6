def delete_cron_jobs_not_in_ui(user)
  crons = (node['dna']['crons'] || []).map{|c| c[:name] if c[:user] == user}.compact

  # get the existing cron jobs created by this cron recipe
  existing_crons_command = Mixlib::ShellOut.new("grep -E -o '\# Chef Name: ui_cron_(.*)' /var/spool/cron/crontabs/#{user}")
  existing_crons_command.run_command
  existing_cron_names = existing_crons_command.stdout
  existing_crons = []

  # get the existing cron names without the prefix ui_cron_
  existing_cron_names.each_line do |line|
    existing_crons << line.chomp.gsub(/\# Chef Name: ui_cron_/,'')
  end
  Chef::Log.debug "current UI cron jobs for #{user} #{existing_crons.inspect}"

  # get the cron jobs for the user
  deleted_crons = existing_crons - crons
  Chef::Log.debug "deleted UI cron jobs for #{user} #{deleted_crons.inspect}"
  deleted_crons.each do |deleted_cron|
    cron "ui_cron_#{deleted_cron}" do
      user user
      action :delete
    end
  end
end

if crontab_instance?(node)
  delete_cron_jobs_not_in_ui(node['owner_name'])
  delete_cron_jobs_not_in_ui("root")

  (node['dna']['crons']||[]).each do |c|
    ui_cron_name = "ui_cron_#{c['name']}"
    cron ui_cron_name do
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
