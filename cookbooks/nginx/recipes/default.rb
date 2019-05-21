recipe = self
stack = node.engineyard.environment['stack_name']
php_fpm = /nginx_fpm/

Chef::Log.debug "Nginx action: #{node['nginx'][:action]}"
nginx_version = node['nginx']['version']
Chef::Log.info "Nginx version: #{nginx_version}"

include_recipe 'nginx::install'
tlsv12_available  = node.openssl.version =~ /1\.0\.1/

Chef::Log.info "instance role: #{node['dna']['instance_role']}"
service "nginx" do
  provider Chef::Provider::Service::Systemd
  action :nothing
  supports :restart => true, :status => true, :reload => true
  only_if { ['solo','app', 'app_master'].include?(node['dna']['instance_role']) }
end

nginx_haproxy_http_port = 8091
nginx_haproxy_https_port = 8092
nginx_xlb_http_port = 8081
nginx_xlb_https_port = 8082

base_port = node['passenger5']['port'].to_i
stepping = 200
app_base_port = base_port
behind_proxy = true

is_passenger = false
is_unicorn = false
is_puma = false


if stack.match(/nginx_passenger5/)
    is_passenger = true
end

if stack.match(/nginx_unicorn/)
    is_unicorn = true
end

if stack.match(/puma/)
    is_puma = true
end

managed_template "/data/nginx/nginx.conf" do
  owner node['owner_name']
  group node['owner_name']
  mode 0644
  source "nginx-plusplus.conf.erb"
  variables(
    lazy {
      {
        :user => node['owner_name'],
        :pool_size => recipe.get_pool_size,
        :behind_proxy => behind_proxy
      }
    }
  )
  notifies node['nginx'][:action], resources(:service => "nginx"), :delayed
end

directory "/data/nginx/ssl" do
  owner node['owner_name']
  group node['owner_name']
  mode 0775
end

file "/data/nginx/http-custom.conf" do
  action :create_if_missing
  owner node['owner_name']
  group node['owner_name']
  mode 0644
end

managed_template "/data/nginx/common/proxy.conf" do
  owner node['owner_name']
  group node['owner_name']
  mode 0644
  source "common.proxy.conf.erb"
  notifies node['nginx'][:action], resources(:service => "nginx"), :delayed
end

managed_template "/data/nginx/common/servers.conf" do
  owner node['owner_name']
  group node['owner_name']
  mode 0644
  source "common.servers.conf.erb"
  notifies node['nginx'][:action], resources(:service => "nginx"), :delayed
end

file "/data/nginx/servers/default.conf" do
  owner node['owner_name']
  group node['owner_name']
  mode 0644
  notifies node['nginx'][:action], resources(:service => "nginx"), :delayed
end

# Issue https://github.com/engineyard/ey-cookbooks-dev-v6/issues/11 needs to be fixed for that to work
(node['dna']['removed_applications']||[]).each do |app|
  execute "remove-old-vhosts-for-#{app}" do
    command "rm -rf /data/nginx/servers/#{app}*"
    notifies node['nginx'][:action], resources(:service => "nginx"), :delayed
  end
end

managed_template "/data/nginx/common/fcgi.conf" do
  owner node['owner_name']
  group node['owner_name']
  mode 0644
  source "common.fcgi.conf.erb"
  notifies node['nginx']['action'], resources(:service => "nginx"), :delayed
end

node.engineyard.apps.each_with_index do |app, index|

    app_base_port = base_port + ( stepping * index )
    dhparam_available = app.metadata('dh_key',nil)

  if node.engineyard.environment.ruby?
    template "/data/nginx/servers/#{app.name}.conf" do
      owner node['owner_name']
      group node['owner_name']
      mode 0644
      source "nginx_app.conf.erb"
      variables({
        :unicorn => is_unicorn,
        :passenger => is_passenger,
        :puma => is_puma,
        :ssl => false,
        :vhost => app.vhosts.first,
        :haproxy_nginx_port => nginx_haproxy_http_port,
        :xlb_nginx_port => nginx_xlb_http_port,
        :upstream_port => app_base_port,
        :http2 => false
      })
      notifies :restart, resources(:service => "nginx"), :delayed
    end
  elsif stack.match(php_fpm)
    php_webroot = node.engineyard.environment.apps.first['components'].find {|component| component['key'] == 'app_metadata'}['php_webroot']
    managed_template "/data/nginx/servers/#{app.name}.conf" do
      owner node['owner_name']
      group node['owner_name']
      mode 0644
      source "fpm-server.conf.erb"
      variables({
        :application => app,
        :app_name => app.name,
        :http_bind_port => nginx_haproxy_http_port,
        :server_names => app.vhosts.first.domain_name.empty? ? [] : [app.vhosts.first.domain_name],
        :webroot => php_webroot,
        :env_name => node.engineyard.environment[:name],
		    :http2 => node['nginx']['http2']
      })
      notifies node['nginx']['action'], resources(:service => "nginx"), :delayed
    end
  end

  directory "/data/nginx/ssl/#{app.name}" do
    owner node['owner_name']
    group node['owner_name']
    mode 0775
  end

  directory "/data/nginx/servers/#{app.name}" do
    owner node['owner_name']
    group node['owner_name']
    mode 0775
  end

  directory "/data/nginx/ssl/#{app.name}" do
    owner node['owner_name']
    group node['owner_name']
    mode 0775
  end

  file "/data/nginx/servers/#{app.name}/custom.conf" do
    action :create_if_missing
    owner node.engineyard.environment.ssh_username
    group node.engineyard.environment.ssh_username
    mode 0644
  end

  if dhparam_available
    managed_template "/data/nginx/ssl/#{app.name}/dhparam.#{app.name}.pem" do
       owner node['owner_name']
       group node['owner_name']
       mode 0600
       source "dhparam.erb"
       variables ({
         :dhparam => app.metadata('dh_key')
       })
       notifies node['nginx'][:action], resources(:service => "nginx"), :delayed
    end
  end

  managed_template "/data/nginx/servers/#{app.name}.users" do
    owner node['owner_name']
    group node['owner_name']
    mode 0644
    source "users.erb"
    variables({
      :application => app
    })
    notifies node['nginx'][:action], resources(:service => "nginx"), :delayed
  end

  managed_template "/etc/nginx/listen_http.port" do
    owner node['owner_name']
    group node['owner_name']
    mode 0644
    source "listen-http.erb"
    variables({
        :http_bind_port => nginx_haproxy_http_port,
    })
    notifies node['nginx'][:action], resources(:service => "nginx"), :delayed
  end

  # if there is an ssl vhost
   if app.https?

     # Can be removed when no one is on nodejs-v2 stack
     file "/data/nginx/servers/#{app.name}.custom.ssl.conf" do
       action :delete
     end

     file "/data/nginx/servers/#{app.name}/custom.ssl.conf" do
       action :create_if_missing
       owner node.engineyard.environment.ssh_username
       group node.engineyard.environment.ssh_username
       mode 0644
     end

     template "/data/nginx/servers/#{app.name}.ssl.conf" do
       owner node['owner_name']
       group node['owner_name']
       mode 0644
       source "nginx_app.conf.erb"
       variables({
           :unicorn => is_unicorn,
           :passenger => is_passenger,
           :puma => is_puma,
           :ssl => true,
           :vhost => app.vhosts.first,
           :haproxy_nginx_port => nginx_haproxy_https_port,
           :xlb_nginx_port => nginx_xlb_https_port,
           :upstream_port => app_base_port,
           :http2 => node['nginx']['http2']
       })
       notifies :restart, resources(:service => "nginx"), :delayed
     end

     template "/data/nginx/ssl/#{app.name}/#{app.name}.key" do
       owner node['owner_name']
       group node['owner_name']
       mode 0644
       source "sslkey.erb"
       backup 0
       variables(
         :key => app[:vhosts][1][:key]
       )
       notifies node['nginx'][:action], resources(:service => "nginx"), :delayed
     end

     template "/data/nginx/ssl/#{app.name}/#{app.name}.crt" do
       owner node['owner_name']
       group node['owner_name']
       mode 0644
       source "sslcrt.erb"
       backup 0
       variables(
         :crt => app[:vhosts][1][:crt],
         :chain => app[:vhosts][1][:chain]
       )
       notifies node['nginx'][:action], resources(:service => "nginx"), :delayed
     end

       # Add Cipher chain
       template "/data/nginx/ssl/#{app.name}/default.ssl_cipher" do
         owner node['owner_name']
         group node['owner_name']
         mode 0644
         source "default_ssl_cipher.erb"
         backup 3
         variables(
           :app_name => app.name,
           :tlsv12_available => tlsv12_available,
           :dhparam_available => dhparam_available
         )
         notifies node['nginx'][:action], resources(:service => "nginx"), :delayed
       end

     # Chain files are create if missing and do not reload Nginx

     # Add Cipher chain
     template "/data/nginx/ssl/#{app.name}/customer.ssl_cipher" do
       owner node['owner_name']
       group node['owner_name']
       mode 0644
       source "customer_ssl_cipher.erb"
       action :create_if_missing
       variables(
         :app_name => app.name
       )
     end

     # Add Cipher chain
     template "/data/nginx/ssl/#{app.name}/ssl_cipher" do
       owner node['owner_name']
       group node['owner_name']
       mode 0644
       source "main_ssl_cipher.erb"
       action :create_if_missing
       variables(
         :app_name => app.name
       )
     end

     template "/data/nginx/ssl/#{app.name}/#{app.name}.pem" do
       owner node['owner_name']
       group node['owner_name']
       mode 0644
       source "sslpem.erb"
       backup 0
       variables(
         :crt => app[:vhosts][1][:crt],
         :chain => app[:vhosts][1][:chain],
         :key => app[:vhosts][1][:key]
       )
     end


     # PHP SSL template
     if stack.match(php_fpm)
       managed_template "/data/nginx/servers/#{app.name}.ssl.conf" do
         owner node['owner_name']
         group node['owner_name']
         mode 0644
         source "fpm-ssl.conf.erb"
         variables({
           :application => app,
           :app_name   => app.name,
           :http_bind_port => nginx_haproxy_https_port,
           :server_names =>  app[:vhosts][1][:name].empty? ? [] : [app[:vhosts][1][:name]],
           :webroot => php_webroot,
           :env_name => node.engineyard.environment[:name]
         })
         notifies node['nginx'][:action], resources(:service => "nginx"), :delayed
       end

       managed_template "/etc/nginx/servers/#{app.name}/additional_server_blocks.ssl.customer" do
         owner node['owner_name']
         group node['owner_name']
         mode 0644
         variables({
           :app_name   => app.name,
           :server_name => (app.vhosts.first.domain_name.empty? or app.vhosts.first.domain_name == "_") ? "www.domain.com" : app.vhosts.first.domain_name,
         })
         source "additional_server_blocks.ssl.customer.erb"
         not_if { File.exists?("/etc/nginx/servers/#{app.name}/additional_server_blocks.ssl.customer") }
       end
       managed_template "/etc/nginx/servers/#{app.name}/additional_location_blocks.ssl.customer" do
         owner node['owner_name']
         group node['owner_name']
         mode 0644
         source "additional_location_blocks.ssl.customer.erb"
         not_if { File.exists?("/etc/nginx/servers/#{app.name}/additional_location_blocks.ssl.customer") }
       end
     end
 end

  # CC-260: Chef 10 could not handle two managed template blocks using the same
  # name with different ifs, so since this can be determined during compile
  # time values, we can use just a regular if statement

end

existing_apps = `cd /data/nginx/servers && ls -d */  |rev | cut -c 2- | rev`.split

existing_apps.each do |existing_app|
  unless node['dna']['applications'].include? existing_app
    execute 'Remove SSL files of detached apps' do
      command %Q{rm -rf /data/nginx/ssl/#{existing_app}}
    end
    execute 'Remove nginx config files of detached apps' do
      command %Q{rm -rf /data/nginx/servers/#{existing_app} && rm -rf /data/nginx/servers/#{existing_app}.*}
    end
  end
end


service "start nginx" do
  service_name "nginx"
  provider Chef::Provider::Service::Systemd
  supports :status => true, :restart => true, :reload => true
  action [:start, :enable]
end
