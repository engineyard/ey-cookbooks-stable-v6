# Expects configuration to already be done.
#

# Update HAProxy

package 'haproxy' do
  action :upgrade
end

service 'haproxy' do
  action :enable
  supports :status => true, :restart => true, :start => true
  subscribes :restart, resources(:package => 'haproxy'), :immediately
end
