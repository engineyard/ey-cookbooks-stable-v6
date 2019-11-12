#
# Cookbook Name:: fail2ban
# Recipe:: services
#
#

ey_cloud_report "Fail2Ban-service" do
  message "Fail2Ban service & monitoring"
end

# enabling the service
service 'fail2ban' do
  supports [:status => true, :restart => true]
  action [:enable]
end
