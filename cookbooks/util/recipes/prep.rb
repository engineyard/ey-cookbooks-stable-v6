include_recipe "deploy-keys"
include_recipe "ey-cron"

case node.engineyard.environment['db_stack_name']
when /postgres/
  include_recipe "postgresql::default"
when /mysql/, /aurora/, /mariadb/
  include_recipe "mysql::client"
  include_recipe "mysql::user_my.cnf"
when "no_db"
  #no-op
end

include_recipe 'app::remove'
include_recipe 'app::create'
include_recipe "app-logs"
#TODOv6 include_recipe "db_admin_tools"
include_recipe "ey-db-libs"
