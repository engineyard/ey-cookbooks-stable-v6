#
# Cookbook Name:: packages
# Recipe:: default
#

Chef::Log.info "PACKAGES: #{node['packages']}"
node['packages']['install'].each do |package|

  Chef::Log.info "PACKAGES: Installing #{package['name']}-#{package['version']}"

  package package['name'] do
    version package['version']
    action :install
    ignore_failure true
  end

end
