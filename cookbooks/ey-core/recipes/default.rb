#TODOv6 include_recipe 'prechef'  # always
#TODOv6 include_recipe 'sysctl::tune'
include_recipe "ey-core::swap"

#TODOv6 include_recipe 'emerge'
#TODOv6 include_recipe 'security_updates'

#TODOv6 include_recipe 'ntp'
#TODOv6 include_recipe 'openssl'

#TODOv6 include_recipe 'ey-instance-api' # potentially move/absorb into other recipe

#TODOv6 include_recipe 'sysklogd'
#TODOv6 include_recipe 'timezones'
#nuke?: include_recipe 'atd'
include_recipe 'logrotate'
include_recipe 'run-one'

#TODOv6 include_recipe 'ey-hosts'
