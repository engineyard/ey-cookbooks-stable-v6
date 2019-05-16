if node.engineyard.environment.ruby?
  default[:ruby][:version] = node.engineyard.environment.ruby[:version]
end
