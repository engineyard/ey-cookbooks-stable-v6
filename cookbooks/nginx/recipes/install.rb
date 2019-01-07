nginx_version = node['nginx']['version']

execute "upgrade_nginx" do
  action :nothing
  user 'root'
  command '/etc/init.d/nginx upgrade'
  only_if %Q{
    [[ -f /var/run/nginx.pid && "$(readlink -m /proc/$(cat /var/run/nginx.pid)/exe)" =~ '/usr/sbin/nginx' ]]
  }
  guard_interpreter :bash
end

ey_cloud_report "nginx" do
  message "processing nginx"
end

# Mask nginx on non-app instances
if node['nginx']['systemd_mask']
  link "/etc/systemd/system/nginx.service" do
    to "/dev/null"
    notifies :run, "execute[reload-systemd]", :immediately
  end
else
  file "/etc/systemd/system/nginx.service" do
    action :delete
    only_if %Q{[ -L /etc/systemd/system/nginx.service ] && [ "$(readlink /etc/systemd/system/nginx.service)" = "/dev/null" ]}
    notifies :run, "execute[reload-systemd]", :immediately
  end
end

package "nginx" do
  version nginx_version
end

directory "/var/log/engineyard/nginx" do
  owner 'root'
  group 'root'
  mode 0755
end

%w{/data/nginx/servers /data/nginx/common}.each do |dir|
  directory dir do
    owner node['owner_name']
    group node['owner_name']
    mode 0755
    recursive true
  end
end

unless File.symlink?("/var/log/nginx")
  directory "/var/log/nginx" do
    action :delete
    recursive true
  end
end

link "/var/log/nginx" do
  to "/var/log/engineyard/nginx"
end

execute "remove /etc/nginx" do
  command "rm -rf /etc/nginx"
  action :run

  not_if %Q{[ -L /etc/nginx ] && [ "$(readlink /etc/nginx)" = "/data/nginx" ]}
end

link "/etc/nginx" do
  to "/data/nginx"

  not_if %Q{[ -L /etc/nginx ] && [ "$(readlink /etc/nginx)" = "/data/nginx" ]}
end

cookbook_file "/data/nginx/mime.types" do
  owner node['owner_name']
  group node['owner_name']
  mode 0755
  source "mime.types"
end

logrotate "nginx" do
  files "/var/log/engineyard/nginx/*log"
  copy_then_truncate true
  restart_command <<-SH
[ ! -f /var/run/nginx.pid ] || kill -USR1 `cat /var/run/nginx.pid`
  SH
end

managed_template "/data/nginx/nginx_version.conf" do
  owner node.engineyard.environment.ssh_username
  group node.engineyard.environment.ssh_username
  mode 0644
  source "nginx_version.conf.erb"
  variables(
    :version => nginx_version
  )
  notifies :run, resources(:execute => "upgrade_nginx"), :delayed
end
