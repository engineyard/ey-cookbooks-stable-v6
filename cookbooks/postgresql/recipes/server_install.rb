postgres_version = node['postgresql']['short_version']

known_versions = %w[
  9.5.16
  9.6.12
  10.3 10.6 10.7
]

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

install_version = node['postgresql']['latest_version']
package_version = known_versions.detect {|v| v =~ /^#{install_version}/}

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

bash "delete-postgresql-service-from-package" do
  code %Q{
    [[ -n $(systemctl status postgresql | grep "Loaded.*/lib/systemd/system/postgresql.service") ]] && systemctl stop postgresql && rm /lib/systemd/system/postgresql.service
  }
  returns [0, 1]
  action :nothing
  only_if { !File.exist?("#{node['postgresql']['datadir']}/postmaster.pid") }
  notifies :run, "execute[reload-systemd]", :immediately
end

# this ruby block handles if the lock version file is set
# It needs to be done like this since the file isn't present during the compile
# phase on first runs on new instances booted from snapshots
ruby_block 'check lock version' do
  block do
    if File.exists?(node['lock_version_file'])
      install_version  = %x{cat #{node['lock_version_file']}}.strip
      package_version = known_versions.detect {|v| v =~ /^#{install_version}/}
      if package_version.nil?
        Chef::Log.info "Chef does not know about PostgreSQL version #{install_version}"
        exit(1)
      end

      run_context.resource_collection.find(:package => "postgresql-#{postgres_version}").version "#{package_version}-*"
      run_context.resource_collection.find(:package => "postgresql-#{postgres_version}").not_if "apt-cache policy postgresql-#{postgres_version} | grep -E 'Installed.*#{package_version}-'"
    end
  end
end

package "postgresql-#{postgres_version}" do
  notifies :run, "bash[delete-postgresql-service-from-package]", :immediately
end

package "postgresql-server-dev-#{postgres_version}" do

end

template "/etc/profile.d/postgresql.sh" do
  source "postgresql.sh.erb"
  variables version: postgres_version
end
