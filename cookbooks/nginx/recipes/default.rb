recipe = self
stack = node.engineyard.environment['stack_name']
php_fpm = /nginx_fpm/

Chef::Log.debug "Nginx action: #{node['nginx'][:action]}"
nginx_version = node['nginx']['version']
Chef::Log.info "Nginx version: #{nginx_version}"

include_recipe 'nginx::install'

Chef::Log.info "instance role: #{node['dna']['instance_role']}"
service "nginx" do
  provider Chef::Provider::Service::Systemd
  action :nothing
  supports :restart => true, :status => true, :reload => true
  only_if { ['solo','app', 'app_master'].include?(node['dna']['instance_role']) }
end

behind_proxy = true
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

file "/data/nginx/http-custom.conf" do
  action :create_if_missing
  owner node['owner_name']
  group node['owner_name']
  mode 0644
end

directory "/data/nginx/ssl" do
  owner node['owner_name']
  group node['owner_name']
  mode 0775
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

(node['dna']['removed_applications']||[]).each do |app|
  execute "remove-old-vhosts-for-#{app}" do
    command "rm -rf /data/nginx/servers/#{app}*"
    notifies node['nginx'][:action], resources(:service => "nginx"), :delayed
  end
end

node.engineyard.apps.each_with_index do |app, index|

  directory "/data/nginx/servers/#{app.name}" do
    owner node['owner_name']
    group node['owner_name']
    mode 0775
  end

  directory "/data/nginx/servers/#{app.name}/ssl" do
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

  # HAX for SD-4650
  # Remove it when awsm stops using dnapi to generate the dna and allows configure ports
  meta = node.engineyard.apps.detect {|a| a.metadata?(:nginx_http_port) }
  nginx_http_port = ( meta and meta.metadata?(:nginx_http_port) ) || 8081
  #nginx_http_port = 8081

  managed_template "/etc/nginx/listen_http.port" do
    owner node['owner_name']
    group node['owner_name']
    mode 0644
    source "listen-http.erb"
    variables({
        :http_bind_port => nginx_http_port,
    })
    notifies node['nginx'][:action], resources(:service => "nginx"), :delayed
  end

  # CC-260: Chef 10 could not handle two managed template blocks using the same
  # name with different ifs, so since this can be determined during compile
  # time values, we can use just a regular if statement

  if stack.match(/nginx_unicorn/)
    managed_template "/data/nginx/servers/#{app.name}.conf" do
      owner node['owner_name']
      group node['owner_name']
      mode 0644
      source "server.conf.erb"
      variables(
        lazy {
          {
            :application => app,
            :app_name   => app.name,
            :http_bind_port => nginx_http_port,
            :server_names => app.vhosts.first.domain_name.empty? ? [] : [app.vhosts.first.domain_name],
			      :http2 => node['nginx']['http2']
          }
        }
      )
      notifies node['nginx'][:action], resources(:service => "nginx"), :delayed
    end
  end
end

service "start nginx" do
  service_name "nginx"
  provider Chef::Provider::Service::Systemd
  supports :status => true, :restart => true, :reload => true
  action [:start, :enable]
end
