# Report to Cloud dashboard
ey_cloud_report "processing php composer.rb" do
  message "processing php - composer"
end

custom_composer = fetch_env_var(node, 'EY_COMPOSER') || ""

template "/tmp/composer-install.sh" do
  owner node["owner_name"]
  group node["owner_name"]
  mode "0644"
  source "composer.erb"
  variables({
    :user => node.engineyard.environment.ssh_username,
    :composer => custom_composer

  })
end

execute "install composer" do
  command "sh /tmp/composer-install.sh && rm /tmp/composer-install.sh"
end


cookbook_file "/usr/bin/composer" do
  owner node["owner_name"]
  group node["owner_name"]
  mode 0755
  source "composer.sh"
  backup 0
end
