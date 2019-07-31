if fetch_env_var(node, "EY_REDIS_ENABLED")
  include_recipe 'redis'
end
