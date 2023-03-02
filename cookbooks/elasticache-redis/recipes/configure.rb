#
# Cookbook Name:: redis
# Recipe:: configure
#

if node['elasticache-redis']['ey_elastic_redis_enabled']

  if node['elasticache-redis']['ey_redis']
    raise "ERROR both EY_REDIS and EY_ELASTICACHE_REDIS_ENABLED Enabled"
  end

  if node['elasticache-redis']['ey_elastic_redis_url'].nil? || node['elasticache-redis']['ey_elastic_redis_url'].empty?
    raise "ERROR EY_ELASTICACHE_REDIS_URL not Set"
  end

  Chef::Log.info("Conofiguring Redis (redis.yml) for elasticache-redis")

  if ['solo', 'app', 'app_master'].include?(node['dna']['instance_role'])

    node['dna']['applications'].each do |app, data|
      template "/data/#{app}/shared/config/redis.yml"do
        source 'redis.yml.erb'
        owner node['owner_name']
        group node['owner_name']
        mode 0655
        backup 0
        variables({
          'environment' => node['dna']['engineyard']['environment']['framework_env'],
          'hostname' => node['elasticache-redis']['ey_elastic_redis_url']
        })
      end
    end

  end

end
