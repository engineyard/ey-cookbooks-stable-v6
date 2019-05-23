redis_version = node['redis']['version']

package "redis" do
  version redis_version
  action :install
end
