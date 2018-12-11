memcached_version = node['memcached']['version']
memcached_download_url = node['memcached']['download_url']
memcached_installer_directory = '/opt/memcached-installer'

Chef::Log.info "Installing memcached #{memcached_version} from source"

# required when installing memcached from source
package "libevent-dev"

execute "create memcache user" do
  command "adduser --system --home /nonexistent --no-create-home --group memcache"
  not_if "getent passwd memcache"
end

directory "/var/run/memcached" do
  owner "memcache"
  group "memcache"
  mode 0755
  recursive true
  action :create
end

remote_file "/opt/memcached-#{memcached_version}.tar.gz" do
  source "#{memcached_download_url}"
  owner node[:owner_name]
  group node[:owner_name]
  mode 0644
  backup 0
end

memcached_installed_version = Mixlib::ShellOut.new 'memcached --version'
memcached_installed_version.run_command
if memcached_installed_version.stdout.chomp == "memcached #{memcached_version}"
  Chef::Log.info "memcached #{memcached_version} is already installed. Skipping installation"
else
  execute "unarchive Memcached installer" do
    cwd "/opt"
    command "tar zxf memcached-#{memcached_version}.tar.gz && sync"
  end

  execute "Remove old memcached-installer" do
    command "rm -rf /opt/memcached-installer"
  end

  execute "rename /opt/memcached-#{memcached_version} to /opt/memcached-installer" do
    command "mv /opt/memcached-#{memcached_version} #{memcached_installer_directory}"
  end

  execute "run memcached-installer/configure, make, install" do
    cwd memcached_installer_directory
    command "./configure && make && make install"
  end
end

cookbook_file "/etc/systemd/system/memcached.service" do
  source "memcached.service"
  owner "root"
  group "root"
  mode 0644
end

directory "/usr/local/share/memcached/scripts" do
  owner "root"
  group "root"
  mode 0755
  recursive true
  action :create
end

template "/usr/local/share/memcached/scripts/systemd-memcached-wrapper" do
  source "systemd-memcached-wrapper.erb"
  owner "root"
  group "root"
  mode 0755
  variables memcached_path: "/usr/local/bin/memcached"
end
