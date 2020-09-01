env_components = attribute['dna']['engineyard']['environment']['components']

version = begin
            env_components.find {|node| node['key'] == 'nodejs'}['value']
          rescue NoMethodError
            nil
          end

fallback_nodejs_version = case version
                          when 'nodejs_10'
                            '10.17.0'
                          when 'nodejs_9'
                            '9.11.2'
                          when 'nodejs_8'
                            '8.16.2'
                          when 'nodejs_6'
                            '6.17.1'
                          when 'nodejs_5'
                            '5.12.0'
                          when 'nodejs_4'
                            '4.9.1'
                          else
                            '10.17.0'
                          end

default['nodejs']['version'] = fetch_env_var(node, 'EY_NODEJS_VERSION') || node.engineyard.environment.metadata('nodejs_version', fallback_nodejs_version)
