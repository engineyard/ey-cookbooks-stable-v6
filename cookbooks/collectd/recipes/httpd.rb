include_recipe "nginx::install"

# The above include will cause nginx to be listening unnecessarily
# on port 81 on db / util instances, so we stop it here.
#
# TODO: Split the nginx recipe up so we can include only what we
#       need in this recipe
# TODOv6
unless %w(app_master app solo).include?(node['dna']['instance_role'])
  service "nginx" do
    action :stop
    only_if "/etc/init.d/nginx status"
  end
end

directory "/var/www/localhost/htdocs" do
  owner node.engineyard.environment.ssh_username
  group node.engineyard.environment.ssh_username
  mode 0755
  recursive true
end

directory "/etc/collectd-httpd" do
  owner node.engineyard.environment.ssh_username
  group node.engineyard.environment.ssh_username
  mode 0755
  recursive true
end

template "/etc/collectd-httpd/collectd-httpd.conf" do
  owner node.engineyard.environment.ssh_username
  group node.engineyard.environment.ssh_username
  mode 0644
  variables({
    :user => node.engineyard.environment.ssh_username
  })
  source "collectd-httpd.conf.erb"
end

service 'fcgiwrap' do
  provider Chef::Provider::Service::Systemd
  action :nothing
end

package 'fcgiwrap' do
  version '1.1.0-10'
end

directory "/etc/systemd/system/fcgiwrap.service.d" do
  owner "root"
  group "root"
  mode 0755
  recursive true
end

cookbook_file "/etc/systemd/system/fcgiwrap.service.d/override.conf" do
  source "fcgiwrap_override.conf"
  owner "root"
  group "root"
  mode 0644
  notifies :run, "execute[reload-systemd]", :delayed
  notifies :enable, "service[fcgiwrap]", :delayed
  notifies :restart, "service[fcgiwrap]", :delayed
end

service "collectd-httpd" do
  provider Chef::Provider::Service::Systemd
  action :nothing
end

cookbook_file "/etc/systemd/system/collectd-httpd.service" do
  source 'collectd-httpd.service'
  owner 'root'
  group 'root'
  mode 0644
  notifies :run, "execute[reload-systemd]", :immediately
  notifies :enable, "service[collectd-httpd]", :immediately
  notifies :start, "service[collectd-httpd]", :immediately
end

package "apache2-utils"

# Setup HTTP auth so AWSM can get at the graphs
execute "install-http-auth" do
  command %Q{
    htpasswd -cb /etc/collectd-httpd/collectd-httpd.users engineyard #{node.engineyard.environment['stats_password']}
  }
end

execute "ensure-newest-nginx" do
  command %Q{
    systemctl restart collectd-httpd
  }
  only_if %Q{
    [[ -f /var/run/collectd-httpd.pid && "$(readlink -m /proc/$(cat /var/run/collectd-httpd.pid)/exe)" =~ '/usr/sbin/nginx' ]]
  }
  guard_interpreter :bash
end
