ey_cloud_report "building load balancer" do
  message '  installing load balancer'
end

include_recipe 'haproxy::install'
