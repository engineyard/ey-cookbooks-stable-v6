if node.engineyard.environment.ruby?
  env_var_ruby = fetch_env_var(node, "EY_RUBY_VERSION")
  if env_var_ruby
    default[:ruby][:version] = env_var_ruby
  else
    default[:ruby][:version] = node.engineyard.environment.ruby[:version]
  end

  if is_ruby_jemalloc_enabled(node)
    default[:ruby][:name] = 'rubyjemalloc'
  else
    default[:ruby][:name] = 'ruby'
  end
end
