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

  # the recipes are monit, nginx, and depending on the stack passenger5, puma, or unicorn
  app.recipes.each do |recipe|
    next if recipe == "memcached"
    include_recipe recipe
  end

end

<<<<<<< HEAD
include_recipe "env_vars::init"
=======
include_recipe "env_vars"
>>>>>>> e9e0ae0548935374e355d877e0f7793ec1c45dae
include_recipe "env_vars::cloud"
include_recipe "cdn_distribution::default"
