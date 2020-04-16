postgres_version = node['postgresql']['short_version']
install_version = node['postgresql']['latest_version']
known_versions = %w[
  9.5.17 9.5.18 9.5.21
  9.6.13 9.6.14 9.6.17
  10.7 10.8 10.9 10.12
  11.3 11.4 11.7
]
package_version = known_versions.detect {|v| v =~ /^#{install_version}/}

execute "dropping lock version file" do
  command "echo #{running_pg_version} > #{node['lock_version_file']}"
  action :run
  only_if { lock_db_version and not File.exists?(node['lock_version_file']) and pg_running }
end

execute "remove lock version file" do
  command "rm #{node['lock_version_file']}"
  only_if { not lock_db_version and File.exists?(node['lock_version_file']) }
end

ey_cloud_report "postgresql" do
  message "Handling PostgreSQL Install"
end

directory "/etc/postgresql-common" do
  action :create
end

cookbook_file "/etc/postgresql-common/createcluster.conf" do
  source "createcluster.conf"
end

cookbook_file "/etc/apt/sources.list.d/pgdg.list" do
  source "pgdg.list"
end

execute "wget -q https://www.postgresql.org/media/keys/ACCC4CF8.asc -O - | sudo apt-key add -" do
  notifies :run, "execute[update-apt]", :immediately
end

directory "/tmp/src/postgresql" do
  action :create
  recursive true
end

# This ruby block handles if the lock version file is set
# It needs to be done like this since the file isn't present during the compile
# phase on first runs on new instances booted from snapshots
# If a lock version file exists, use the version to set the variables
# on template "/tmp/src/postgresql/install.sh"
ruby_block 'check lock version' do
  block do
    if File.exists?(node['lock_version_file'])
      install_version = %x{cat #{node['lock_version_file']}}.strip
    else
      install_version = node['postgresql']['latest_version']
    end
    package_version = known_versions.detect {|v| v =~ /^#{install_version}/}
    if package_version.nil?
      Chef::Log.info "Chef does not know about PostgreSQL version #{install_version}"
      exit(1)
    end

    run_context.resource_collection.find(:template => "/tmp/src/postgresql/install.sh").variables package_version: package_version, postgres_version: postgres_version
  end
end

template "/tmp/src/postgresql/install.sh" do
  source "install.sh.erb"
  owner 'root'
  group 'root'
  mode '0755'
  variables package_version: package_version, postgres_version: postgres_version
end

# Install postgresql packages using a script
execute "run postgresql install.sh" do
  command "/tmp/src/postgresql/install.sh"
end

template "/etc/profile.d/postgresql.sh" do
  source "postgresql.sh.erb"
  variables version: postgres_version
end
