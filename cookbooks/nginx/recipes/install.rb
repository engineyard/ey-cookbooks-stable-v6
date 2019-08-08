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

package "nginx"

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
