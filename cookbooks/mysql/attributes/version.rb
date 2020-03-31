lock_major_version = %x{[ -f "/db/.lock_db_version" ] && grep -E -o '^[0-9]+\.[0-9]+' /db/.lock_db_version }
db_stack = lock_major_version == '' ? attribute['dna']['engineyard']['environment']['db_stack_name'] :  "mysql#{lock_major_version.gsub(/\./, '_').strip}"

default['latest_version_56'] = '5.6.47'
default['latest_version_57'] = '5.7.29'
default['latest_version_80'] = '8.0.18'
major_version=''

case db_stack
when 'mysql5_6', 'aurora5_6', 'mariadb10_0'
  major_version = '5.6'
  default['mysql']['latest_version'] = node['latest_version_56']
  
when 'mysql5_7', 'aurora5_7', 'mariadb10_1'
  major_version = '5.7'
  default['mysql']['latest_version'] = node['latest_version_57']

when 'mysql8_0'
  major_version = '8.0'
  default['mysql']['latest_version'] = node['latest_version_80']
end

default['mysql']['short_version'] = major_version
default['mysql']['logbase'] = "/db/mysql/#{major_version}/log/"
default['mysql']['datadir'] = "/db/mysql/#{major_version}/data/"
default['mysql']['ssldir'] = "/db/mysql/#{major_version}/ssl/"
default['mysql']['dbroot'] = '/db/mysql/'
default['mysql']['owner'] = 'mysql'
