ey_cloud_report "load balancer" do
  message 'setting up load balancer'
end

include_recipe 'lb::prep'
include_recipe 'lb::build'
