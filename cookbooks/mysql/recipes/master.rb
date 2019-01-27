ey_cloud_report "mysql" do
  message "processing mysql"
end

include_recipe 'db-ssl::setup'
include_recipe "mysql::install"
include_recipe "mysql::user_my.cnf"

directory "/db/mysql" do
  owner "mysql"
  group "mysql"
  mode 0755
  recursive true
end

directory node['mysql']['logbase'] do
  owner "mysql"
  group "mysql"
  mode 0755
  recursive true
end

include_recipe "mysql::startup"

set_root_mysql_password = case node['mysql']['short_version']
  when '5.6'
    %Q{
      /usr/bin/mysqladmin -u root password '#{node.engineyard.environment['db_admin_password']}' || /usr/bin/mysqladmin -u root --password='' password '#{node.engineyard.environment['db_admin_password']}'; true
    }
  when '5.7'
    %Q{
      mysql -u root -e "ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY '#{node.engineyard.environment['db_admin_password']}'"; true
    }
  end

execute "set-root-mysql-pass" do
  command set_root_mysql_password
end

include_recipe "mysql::cleanup" if node['mysql']['short_version'] == '5.6' # MySQL 5.7 doesn't include extra users/databases by default

include_recipe "mysql::setup_app_users_dbs"

include_recipe "ey-backup::mysql"
