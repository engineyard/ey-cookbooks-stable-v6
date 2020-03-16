module RDSHelpers
  def db_host_is_rds?
    node.engineyard.environment[:db_provider_name] == 'amazon_rds'
  end
end

class Chef
  class Recipe
    include RDSHelpers
  end

  class Resource
    include RDSHelpers
  end
end
