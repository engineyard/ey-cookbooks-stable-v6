# Update OpenSSL
Chef::Log.info "OpenSSL Version: #{node['openssl']['version']}"

package 'openssl' do
  version node['openssl']['version']
  action :install
end
