if fetch_env_var(node, "EY_REDIS_ENABLED") =~ /^TRUE$/i
  include_recipe 'redis'
end

if fetch_env_var(node, "EY_MEMCACHED_ENABLED") =~ /^TRUE$/i
  include_recipe 'memcached'
end
