if node.engineyard.environment.ruby?
  env_var_ruby = fetch_env_var(node, "EY_RUBY_VERSION")
  if env_var_ruby
    default[:ruby][:version] = env_var_ruby
  else
    #default[:ruby][:version] = node.engineyard.environment.ruby[:version]
    default[:ruby][:version] = "2.6.3"
  end
end
