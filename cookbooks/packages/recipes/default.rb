#
# Cookbook Name:: packages
# Recipe:: default
#

node['packages']['keys'].each do |key|
  execute "add key from #{key['url']}" do
    command "curl -sS #{key['url']} | apt-key add -"
  end
end

node['packages']['apt_sources'].each do |apt_source|
  file "apt source #{apt_source['name']}" do
    path "/etc/apt/sources.list.d/#{apt_source['name']}.list"
    content apt_source["content"]
    notifies :run, "execute[update-apt]", :immediately
  end
end

node['packages']['install'].each do |package|

  Chef::Log.info "PACKAGES: Installing #{package['name']}-#{package['version']}"

  package package['name'] do
    version package['version']
    action :install
  end

end
