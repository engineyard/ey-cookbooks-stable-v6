# ey-init::integrate runs after adding or removing an instance

case node['dna']['instance_role']
when 'app', 'app_master'
  #TODOv6 include_recipe 'ey-monitor'
  include_recipe 'haproxy'
when 'util'
when /^db/
  if node.engineyard.environment['db_stack_name'][/^postgres/]
    #TODOv6 include_recipe 'ey-backup::postgres'
  end
end
include_recipe "ssh_keys" # CC-691 - update ssh whitelist after takeovers
