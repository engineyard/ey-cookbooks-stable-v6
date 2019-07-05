case attribute['dna']['engineyard']['environment']['db_stack_name']
when "postgres9_5"
  default['postgresql']['latest_version'] = '9.5.17'
  default['postgresql']['short_version'] = '9.5'
when "postgres9_6"
  default['postgresql']['latest_version'] = '9.6.13'
  default['postgresql']['short_version'] = '9.6'
when "postgres10"
  default['postgresql']['latest_version'] = '10.9'
  default['postgresql']['short_version'] = '10'
when "postgres11"
  default['postgresql']['latest_version'] = '11.4'
  default['postgresql']['short_version'] = '11'
end
default['postgresql']['datadir'] = "/db/postgresql/#{node['postgresql']['short_version']}/data/"
default['postgresql']['ssldir'] = "/db/postgresql/#{node['postgresql']['short_version']}/ssl/"
default['postgresql']['dbroot'] = '/db/postgresql/'
default['postgresql']['owner'] = 'postgres'
default['postgresql']['pgbindir'] = "/usr/lib/postgresql/#{node['postgresql']['short_version']}/bin/"

# postgis
default['postgis']['version'] = "2.5"
default['postgis']['package_name'] = "postgresql-#{default['postgresql']['short_version']}-postgis-#{default['postgis']['version']}"
