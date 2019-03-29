class Chef::Recipe
  include NewrelicHelpers
end

if node['newrelic_infra']['use_newrelic_addon']
  license_key = newrelic_license_key
else
  license_key = node['newrelic_infra']['license_key']
end

display_name = node['newrelic_infra']['display_name']

template "/etc/newrelic-infra.yml" do
  source "newrelic-infra.yml.erb"
  owner "root"
  group "root"
  mode 0600
  backup false
  variables({
    :license_key => license_key,
    :display_name => display_name
  })
end

execute "curl -s https://download.newrelic.com/infrastructure_agent/gpg/newrelic-infra.gpg | sudo apt-key add -" do
end

cookbook_file "/etc/apt/sources.list.d/newrelic-infra.list" do
  source "newrelic-infra.list"
  notifies :run, "execute[update-apt]", :immediately
end

package "newrelic-infra" do
  version node['newrelic_infra']['package_version']
  action :install
end
