node.engineyard.apps.each do |app|
  app.generate_skeleton do |dir|
    directory dir do
      owner node.engineyard.environment.ssh_username
      group node.engineyard.environment.ssh_username
      mode 0755
    end
  end
end

node.engineyard.apps.each do |app|
  dbtype = node.engineyard.environment.db_adapter(app.app_type)

  if dbtype == "nodb"
    Chef::Log.info "--- Source file for db #{dbtype} -  dropping nodb file"

     managed_template "/data/#{app.name}/shared/config/nodatabase.yml" do
      owner node.engineyard.environment.ssh_username
      group node.engineyard.environment.ssh_username
      mode 0600
      source "nodatabase.yml.erb"
    end
  else
    Chef::Log.info "--- Dropping db.yml file for db #{dbtype}"

    # check if we need to add the determine_adapter erb to template
    if !!(dbtype[/^mysql/] && app['type'][/^ra(ck|ils[34])$/])
      determine_adapter_code = <<-RUBY
<%
def determine_adapter
  if Gem.loaded_specs.key?("mysql2")
    "mysql2"
  else
    "mysql"
  end
rescue
  "#{dbtype}"
end
%>
      RUBY
      dbtype = '<%= determine_adapter %>'
    end

    managed_template "/data/#{app.name}/shared/config/database.yml" do
      owner node.engineyard.environment.ssh_username
      group node.engineyard.environment.ssh_username
      mode 0600
      source "database.yml.erb"
      variables({
        :determine_adapter_code => determine_adapter_code,
        :environment => node.engineyard.environment['framework_env'],
        :dbuser => app.database_username,
        :dbpass => app.database_password,
        :dbname => app.database_name,
        :dbhost => node['dna']['db_host'],
        :dbtype => dbtype,
        :slaves => node.engineyard.environment.instances.select{|i| i["role"] =="db_slave"},
        :pool => node.engineyard.environment.jruby? ? node.dna['jruby_pool_size'] : nil,
        :ssl_owner => node.engineyard.environment.ssh_username,
        :include_ssl => !!node.engineyard.environment['db_stack_name'][/^mysql/] && !db_host_is_rds?
      })
    end
  end

=begin TODOv6
  app.recipes.each do |recipe|
    include_recipe recipe
  end
=end
  include_recipe "monit"
  include_recipe "nginx"
  #include_recipe "unicorn"
  #include_recipe "passenger5"
  include_recipe "puma"
end

#TODOv6 include_recipe "env_vars::cloud"
#TODOv6 include_recipe "cdn_distribution::default"