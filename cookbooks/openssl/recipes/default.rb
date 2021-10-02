# Update OpenSSL
package 'openssl' do
  action :install
end

#Install Certificates
execute 'install-ca-certs' do
  command "apt-get -q -y install ca-certificates"
end
