include_recipe "ec2" if ['solo', 'app', 'util', 'app_master','node'].include?(node['dna']['instance_role'])
include_recipe 'ephemeraldisk'

# descriptive hostname

descriptive_hostname = [
  node['dna']['engineyard']['this'],
  node['dna']['environment']['name'],
  node['dna']['instance_role'],
  node['dna']['name'],
  node.name,
  `hostname`
].compact.join(',')

execute "write descriptive_hostname file" do
  command "echo '#{descriptive_hostname}' > /etc/descriptive_hostname"
end

include_recipe "ey-dynamic::user"

directory "/data" do
  owner node["owner_name"]
  group node["owner_name"]
  mode 0755
end

directory "/data/homedirs" do
  owner node["owner_name"]
  group node["owner_name"]
  mode '0755'
end

node['dna']['applications'].each_key do |app|
  directory "/data/#{app}" do
    owner node["owner_name"]
    group node["owner_name"]
    mode '0755'
  end
end

directory "/var/log/engineyard" do
  owner node["owner_name"]
  group node["owner_name"]
  mode '0755'
end

directory "/var/cache/engineyard" do
  owner node["owner_name"]
  group node["owner_name"]
  mode '0755'
end

directory "/tmp/src" do
  owner node["owner_name"]
  group node["owner_name"]
  mode '0755'
end

%w{/engineyard /engineyard/bin}.each do |dir|
  directory dir do
    owner "root"
    group "root"
    mode '0755'
  end
end

cookbook_file '/etc/security/limits.d/90-ey-limits.conf' do
  owner 'root'
  group 'root'
  mode '0644'
  source 'limits.conf'
end

template "/etc/environment" do
  owner 'root'
  group 'root'
  mode '0644'
  source 'environment.erb'
  variables(
    :framework_env => node.engineyard.environment['framework_env']
  )
end

cookbook_file '/etc/default/locale' do
  owner 'root'
  group 'root'
  mode '0644'
  source 'locale'
end

cookbook_file '/root/.profile' do
  owner 'root'
  group 'root'
  source 'profile'
end

# all roles get these recipes
#include_recipe 'ey-cron'
#include_recipe "ey-env"
include_recipe "ey-backup::setup"
#include_recipe "framework_env"
include_recipe "sudo"
include_recipe "ssh_keys"
#include_recipe "prompt"
include_recipe "efs"

# do not run the ruby recipes when we install Node.js and other languages.
#include_recipe "ruby" if node.engineyard.environment.ruby?
