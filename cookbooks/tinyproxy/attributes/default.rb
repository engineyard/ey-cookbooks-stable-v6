default['tinyproxy'].tap do |tinyproxy|

  # Port to listen on
  tinyproxy['port'] = '8888'

  #application to install tinyproxy on
  tinyproxy['app_name'] = "todo_V6"

  # Run Tinyproxy on a named util instance
  # This is the default
  tinyproxy['install_type'] = 'NAMED_UTIL'
  tinyproxy['utility_name'] = 'tinyproxy'

  # Run tinyproxy on the app_master instance
  #tinyproxy['install_type'] = 'APP_MASTER'
end
