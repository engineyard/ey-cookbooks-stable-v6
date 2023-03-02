default['elasticache-redis']['ey_elastic_redis_enabled'] = fetch_env_var(node, "EY_ELASTICACHE_REDIS_ENABLED")
default['elasticache-redis']['ey_elastic_redis_url']     = fetch_env_var(node, "EY_ELASTICACHE_REDIS_URL")
default['elasticache-redis']['ey_redis']                 = fetch_env_var(node, "EY_REDIS_ENABLED")
