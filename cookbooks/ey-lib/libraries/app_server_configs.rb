require_relative 'env_vars'
require_relative 'metadata'

module AppServerConfigs
  module Helper
    def self.included klass
      klass.class_eval do
        # Module dependencies
        include EnvVars::Helper
        include EnvMetadata::Helper
      end
    end

    def app_server_get_worker_memory_size(app)
      # See https://support.cloud.engineyard.com/entries/23852283-Worker-Allocation-on-Engine-Yard-Cloud for more details
      # 1. Default value is 255.0
      mem_size = '255.0'
      # 2. Try to get a value from metadata (this should be removed eventually!)
      mem_size = metadata_app_get_with_default(app.name, :worker_memory_size, mem_size)
      # 3. Try to get a value from the EY environment variable (recommended way)
      mem_size = fetch_env_var_for_app(app, 'EY_WORKER_MEMORY_SIZE', mem_size)
      mem_size
    end
  end
end

class Chef
  class Recipe
    include AppServerConfigs::Helper
  end

  class Resource
    include AppServerConfigs::Helper
  end
end
