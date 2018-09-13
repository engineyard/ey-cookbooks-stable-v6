ey_cloud_report "configuring load balancer" do
  message '  configuring load balancer'
end

include_recipe 'haproxy::kill-others'
include_recipe 'haproxy::configure'
