app_name = node.dna[:applications].keys.first

default['papertrail'].tap do |papertrail|
  papertrail['remote_syslog_version']  = '0.20'
  papertrail['port']                   = 111111111111111 # YOUR PORT HERE
  papertrail['destination_host']       = 'HOST.papertrailapp.com' # YOUR HOST HERE
  papertrail['hostname']               = [app_name, node.dna[:instance_role], `hostname`.chomp].join('_')
  papertrail['other_logs']             = [
    '/var/log/engineyard/nginx/*log',
    '/var/log/engineyard/apps/*/*.log',
    '/var/log/mysql/*.log',
    '/var/log/mysql/mysql.err',
  ]
  papertrail['exclude_patterns']      = [  
    '400 0 "-" "-" "-', # seen in ssl access logs
  ]
  # Install Papertrail to all instances by default
  papertrail['is_papertrail_instance'] = true
end

