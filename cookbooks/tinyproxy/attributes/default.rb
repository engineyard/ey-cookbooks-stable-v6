default['tinyproxy'].tap do |tinyproxy|
  # What version to install
  # Currently only 1.8.4-5 is available on V6
  # Please open a Support ticket if you need a newer version
  tinyproxy['version'] = '1.8.4-5'

  # Port to listen on
  tinyproxy['port'] = '8888'

  # Run Tinyproxy on a named util instance
  # This is the default
  tinyproxy['utility_name'] = 'tinyproxy'
  tinyproxy['is_tinyproxy_instance'] = (
    node['dna']['instance_role'] == 'util' &&
    node['dna']['name'] == tinyproxy['utility_name']
  )

  # Run tinyproxy on the app_master instance
  #tinyproxy['is_tinyproxy_instance'] = (node['dna']['instance_role'] == 'app_master')
end
