#TODOv6 include_recipe 'prechef'  # always
include_recipe 'sysctl::tune'
include_recipe "ey-core::swap"

#TODOv6 include_recipe 'emerge'
include_recipe 'security_updates'

include_recipe 'ntp'
include_recipe 'openssl'

include_recipe 'ey-instance-api' # potentially move/absorb into other recipe

include_recipe 'syslog-ng'
include_recipe 'timezones'
#nuke?: include_recipe 'atd'
include_recipe 'logrotate'
include_recipe 'run-one'

include_recipe 'ey-hosts'
