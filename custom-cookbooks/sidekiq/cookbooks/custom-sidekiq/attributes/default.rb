# More information on how to use this file to customize the Sidekiq cookbook is
# available in custom_sidekiq/README.md
#
# this is the default (run everywhere except on DB instances)
# default['sidekiq']['is_sidekiq_instance'] = !(node['dna']['instance_role'] =~ /^db_/)

# run the recipe on a utility instance named background_workers
# default['sidekiq']['is_sidekiq_instance'] = (node['dna']['instance_role'] == 'util' && node['dna']['name'] == 'background_workers')

# run the recipe on a solo instance
# default['sidekiq']['is_sidekiq_instance'] = (node['dna']['instance_role'] == 'solo')

# Default memory limit
# default['sidekiq']['worker_memory'] = 400
