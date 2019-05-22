default['php']['version'] = case attribute['dna']['engineyard']['environment']['components'].map(&:values).flatten.find(/^php_/).first
  when 'php_71'
    '7.1'
  when 'php_72'
    '7.2'
  when 'php_73'
    '7.3'
  else
    '7.2'
end

default['php']['minor_version'] =  default['php']['version'].split(".").first(2).join(".")
