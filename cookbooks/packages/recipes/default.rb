#
# Cookbook Name:: packages
# Recipe:: default
#

keys = node['packages']['keys'] || []
keys.each do |key|
  execute "add key from #{key['url']}" do
    command "curl -sS #{key['url']} | apt-key add -"
    if key['fingerprint']
      not_if "apt-key adv --list-public-key --with-fingerprint --with-colons | grep #{key['fingerprint']} -q"
    end
  end
end

apt_sources = node['packages']['apt_sources'] || []
apt_sources.each do |apt_source|
  file "apt source #{apt_source['name']}" do
    path "/etc/apt/sources.list.d/#{apt_source['name']}.list"
    content apt_source["content"]
    notifies :run, "execute[update-apt]", :immediately
  end
end

install = node['packages']['install'] || []
install.each do |package|

  Chef::Log.info "PACKAGES: Installing #{package['name']}-#{package['version']}"

  package package['name'] do
    version package['version']
    action :install
    options '--allow-downgrades' if package['allow_downgrades']
  end

end
