php_component_version = attribute['dna']['engineyard']['environment']['components']
  .map(&:values).flatten.find { |cv| cv =~ /^php_/ }

default['php']['version'] = case php_component_version.to_s
  when 'php_71'
    '7.1'
  when 'php_72'
    '7.2'
  when 'php_73'
    '7.3'
  when 'php_74'
    '7.4'
  else
    '7.2'
end

default['php']['known_versions'] = %w[ 7.1 7.2 7.3 7.4 ]
default['php']['minor_version'] =  default['php']['version']
