#TODOv6 include_recipe "ey-cron"
case node.engineyard.environment['db_stack_name']
when /postgres/
  #TODOv6 include_recipe "postgresql::default"
when /mysql/
  include_recipe "mysql"
=begin TODOv6
  include_recipe "mysql::user_my.cnf"
  include_recipe "mysql::master"
  is_solo = ['solo'].include?(node.dna['instance_role'])
  include_recipe "mysql::replication" unless is_solo
  include_recipe "mysql::monitoring"
  include_recipe "mysql::extras"
=end
when "no_db"
  #no-op
end

#TODOv6 include_recipe "db_admin_tools"
