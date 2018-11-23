memcached_package = 'memcached'
memcached_version = node['memcached']['version']

Chef::Log.info "Installing #{memcached_package} #{memcached_version} from package..."

package memcached_package do
  version memcached_version
  action :install
end
