action = node.engineyard.metadata(:nginx_action,:restart)
default['nginx']['version'] = node.engineyard.metadata('nginx_version','1.14.0-0ubuntu1.1')
default['nginx']['action'] = action
default['nginx']['http2'] = false
