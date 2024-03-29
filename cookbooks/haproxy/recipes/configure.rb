# Expect this to run before haproxy::install
#

# We need to do an execute here because a service
# definition requires the init.d file to be in
# place at by this point. And since we configure first
# it won't be on clean instances
execute "reload-haproxy" do
  command 'if /etc/init.d/haproxy status ; then /etc/init.d/haproxy reload; else /etc/init.d/haproxy restart; fi'
  action :nothing
end



directory "/etc/haproxy/errorfiles" do
  action :create
  owner 'root'
  group 'root'
  mode 0755
  recursive true
end

["400.http","403.http","408.http","500.http","502.http","503.http","504.http"].each do |p|
  cookbook_file "/etc/haproxy/errorfiles/#{p}" do
    owner 'root'
    group 'root'
    mode 0644
    backup 0
    source "errorfiles/#{p}"
    not_if { File.exists?("/etc/haproxy/errorfiles/keep.#{p}") }
  end
end


# CC-52
# Add http check for accounts with adequate settings in their dna metadata
haproxy_httpchk_path = (app = node.engineyard.apps.detect {|a| a.metadata?(:haproxy_httpchk_path) } and app.metadata?(:haproxy_httpchk_path))
haproxy_httpchk_host = (app = node.engineyard.apps.detect {|a| a.metadata?(:haproxy_httpchk_host) } and app.metadata?(:haproxy_httpchk_host))

# CC-954: Allow for an app to use specific http check endpoint instead of tcp connectivity check
unless haproxy_httpchk_path
  app = node.engineyard.apps.detect {|a| a.metadata?(:node_health_check_url)}
  if app
    haproxy_httpchk_path = app.metadata(:node_health_check_url)
    haproxy_httpchk_host = app.vhosts.first.domain_name.empty? ? nil : app.vhosts.first.domain_name
  end
end

# FBZ 10372
healthcheck_domain_override = fetch_env_var(node, 'EY_HEALTHCHECK_DOMAIN_OVERRIDE') || false
Chef::Log.info "healthcheck_domain_override: #{healthcheck_domain_override}"
if healthcheck_domain_override
	haproxy_httpchk_host = healthcheck_domain_override
end

managed_template "/etc/haproxy.cfg" do
  owner 'root'
  group 'root'
  mode 0644
  source "haproxy.cfg.erb"
  members = node['dna']['members'] || []
  variables({
    :backends => node.engineyard.environment.app_servers,
    :app_master_weight => members.size < 51 ? (50 - (members.size - 1)) : 0,
    :haproxy_user => node['dna']['haproxy']['username'],
    :haproxy_pass => node['dna']['haproxy']['password'],
    :httpchk_host => haproxy_httpchk_host,
    :httpchk_path => haproxy_httpchk_path,
  })

  # We need to reload to activate any changes to the config
  # but delay it as haproxy may not be installed yet
  notifies :run, resources(:execute => 'reload-haproxy'), :delayed
end

link "/etc/haproxy/haproxy.cfg" do
  to "/etc/haproxy.cfg"
end
