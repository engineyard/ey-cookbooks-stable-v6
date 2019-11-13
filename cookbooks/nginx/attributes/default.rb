action = node.engineyard.metadata(:nginx_action,:restart)
default['nginx']['action'] = action
default['nginx']['http2'] = false
default['nginx']['systemd_mask'] = if %w(app_master app solo).include?(node['dna']['instance_role'])
                                     false
                                   else
                                     # Mask nginx on non-app instances
                                     true
                                   end
default['nginx']['syslog'] = false