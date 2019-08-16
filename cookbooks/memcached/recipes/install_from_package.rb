memcached_package = 'memcached'

Chef::Log.info "Installing #{memcached_package} from package..."

package memcached_package do
  action :install
end
