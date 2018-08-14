ey_cloud_report "mysql" do
  message "processing mysql"
end

#TODOv6 include_recipe "mysql::install"
package "percona-server-server-#{node['mysql']['short_version']}"

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

execute "set-root-mysql-pass" do
  command %Q{
    /usr/bin/mysqladmin -u root password '#{node.engineyard.environment['db_admin_password']}' || /usr/bin/mysqladmin -u root --password='' password '#{node.engineyard.environment['db_admin_password']}'; true
  }
end

=begin
include_recipe "mysql::cleanup" if node['mysql']['short_version'] == '5.6' # MySQL 5.7 doesn't include extra users/databases by default

include_recipe "mysql::setup_app_users_dbs"

include_recipe "ey-backup::mysql"
=end
