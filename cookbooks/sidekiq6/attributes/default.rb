#
# Cookbook Name:: sidekiq6
# Attrbutes:: default
#

default['sidekiq'].tap do |sidekiq|
  
  is_sidekiq_enabled = !!(fetch_env_var(node, 'EY_SIDEKIQ6_ENABLED', 'false') =~ /^TRUE$/i)
  # Sidekiq will be installed on to application/solo instances,
  # unless a utility name is set, in which case, Sidekiq will
  # only be installed on to a utility instance that matches
  # the name
  role_pattern = fetch_env_var(node, 'EY_SIDEKIQ6_INSTANCES_ROLE')
  instance_filter_active = false
  does_role_match = true
  if role_pattern
    instance_filter_active = true
    role_pattern = Regexp.new(role_pattern)
    does_role_match = ! role_pattern.match(node['dna']['instance_role']).nil?
  end
  name_pattern = fetch_env_var(node, 'EY_SIDEKIQ6_INSTANCES_NAME')
  does_name_match = true
  if name_pattern
    instance_filter_active = true
    name_pattern = Regexp.new(name_pattern)
    does_name_match = ! name_pattern.match(node['dna']['name']).nil?
  end
  # Sidekiq workers can't be run on DB instances (no code gets deployed there).
  # Therefore we explicitly filter out DB instances
  is_db_instance = !!(node['dna']['instance_role'] =~ /^db_/)
  # If an instance pattern is active, deactivate DB filter
  db_instance_gate = (instance_filter_active || !is_db_instance)
  sidekiq['is_sidekiq_instance'] = (is_sidekiq_enabled && does_role_match && does_name_match && db_instance_gate)

  # We create an on-instance `after_restart` hook only 
  # when the recipe was enabled via environment variables.
  # Otherwise the behaviour for custom-cookbooks would change
  # which is undesirable.
  sidekiq['create_restart_hook'] = is_sidekiq_enabled

  # Number of workers (not threads)
  sidekiq['workers'] = fetch_env_var(node, 'EY_SIDEKIQ6_NUM_WORKERS', 1).to_i

  # Concurrency
  sidekiq['concurrency'] = fetch_env_var(node, 'EY_SIDEKIQ6_CONCURRENCY', 25).to_i

  # Queues
  sidekiq['queues'] = {
    # :queue_name => priority
    :default => 1
  }
  fetch_env_var_patterns(node, /^EY_SIDEKIQ6_QUEUE_PRIORITY_([a-zA-Z0-9_]+)$/).each do |queue_var|
    queue_name = queue_var[:match][1].to_sym
    queue_priority = queue_var[:value].to_i
    sidekiq['queues'][queue_name] = queue_priority
  end

  # Memory limit
  sidekiq['worker_memory'] = fetch_env_var(node, 'EY_SIDEKIQ6_WORKER_MEMORY_MB', 400).to_i # MB

  # Verbose
  sidekiq['verbose'] = fetch_env_var(node, 'EY_SIDEKIQ6_VERBOSE', false).to_s == "true"

  # Setting this to true installs a cron job that
  # regularly terminates sidekiq workers that aren't being monitored by monit,
  # and terminates those workers
  #
  # default: false
  sidekiq['orphan_monitor_enabled'] = fetch_env_var(node, 'EY_SIDEKIQ6_ORPHAN_MONITORING_ENABLED', false).to_s == "true"

  # sidekiq_orphan_monitor cron schedule
  #
  # default: every 5 minutes
  sidekiq['orphan_monitor_cron_schedule'] = fetch_env_var(node, 'EY_SIDEKIQ6_ORPHAN_MONITORING_SCHEDULE', "*/5 * * * *")
end
