ey_cloud_report "building load balancer" do
  message '  installing load balancer'
end

require_recipe 'haproxy::install'
