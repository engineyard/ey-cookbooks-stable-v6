short_version = node['mysql']['short_version']
if short_version == '8.0'
  config_postfix = '80'
else
  config_postfix = ''
end

template "/tmp/root_perms.sql" do
  owner 'root'
  group 'root'
  mode 0644
  source "default_perms#{config_postfix}.sql.erb"
  variables({
    :dbpass => node.engineyard.environment['db_admin_password'],
  })
end

execute "remove-default-permissions-file" do
  command %Q{
    rm /tmp/root_perms.sql
  }
  action :nothing
end

execute "set-default-permisions" do
  command %Q{
    export MYSQL_PWD=#{node.engineyard.environment['db_admin_password']}; mysql -u root < /tmp/root_perms.sql
  }
  notifies :run, 'execute[remove-default-permissions-file]'
end
