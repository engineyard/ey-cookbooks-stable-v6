redis_version = node['redis']['version']

package "redis" do
  version redis_version
  action :install
  options "-o Dpkg::Options::=\"--force-confdef\" -o Dpkg::Options::=\"--force-confold\""
end
