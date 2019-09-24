#
# Cookbook Name:: shared_db
# Recipe:: default
#

apps = node['shared_db']['apps']
parent_app = node['shared_db']['parent_app']
parent_app_path = "/data/#{parent_app}/shared/config/database.yml"

if apps && parent_app
  for app in apps
    file "/data/#{app}/shared/config/keep.database.yml" do
      owner 'root'
      group 'root'
      mode '0755'
      action :create
    end
	execute "Symlink #{parent_app_path} to /data/#{app}/shared/config/database.yml" do
      command "ln -sf #{parent_app_path} /data/#{app}/shared/config/database.yml"
      only_if "test -f #{parent_app_path}"
    end
  end
end
