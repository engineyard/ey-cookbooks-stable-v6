# Expects configuration to already be done.
#

# Update HAProxy
haproxy_version = node.engineyard.metadata("haproxy_version", node['haproxy']['version'])

Chef::Log.info "HAProxy Version: #{haproxy_version}"

package 'haproxy' do
  version haproxy_version
  action :upgrade
end

service 'haproxy' do
  action :enable
  supports :status => true, :restart => true, :start => true
  subscribes :restart, resources(:package => 'haproxy'), :immediately
end
