include_recipe 'prechef'  # always

execute "reload-systemd" do
  command "systemctl daemon-reload"
  action :nothing
end

execute "reload-monit" do
  command "monit reload"
  action :nothing
end

include_recipe 'sysctl::tune'
include_recipe "ey-core::swap"

include_recipe 'security_updates'

include_recipe 'ntp'
include_recipe 'openssl'

include_recipe 'ey-instance-api' # potentially move/absorb into other recipe

include_recipe 'syslog-ng'
include_recipe 'timezones'
include_recipe 'logrotate'
include_recipe 'run-one'

include_recipe 'ey-hosts'
