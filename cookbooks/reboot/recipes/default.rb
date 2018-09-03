managed_template "/etc/rc.local" do
  source "rc.local.erb"
  owner "root"
  group "root"
  mode "0755"
end
