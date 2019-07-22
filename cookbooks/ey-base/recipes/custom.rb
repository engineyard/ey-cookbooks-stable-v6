if fetch_env_var(node, "EY_REDIS")
  include_recipe 'redis'
end
