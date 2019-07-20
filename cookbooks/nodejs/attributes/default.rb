env_components = attribute['dna']['engineyard']['environment']['components']

version = begin
            env_components.find {|node| node['key'] == 'nodejs'}['value']
          rescue NoMethodError
            nil
          end

fallback_nodejs_version = case version
                          when 'nodejs_10'
                            '10.16.0'
                          when 'nodejs_9'
                            '9.11.2'
                          when 'nodejs_8'
                            '8.12.0'
                          when 'nodejs_6'
                            '6.14.4'
                          when 'nodejs_5'
                            '5.12.0'
                          when 'nodejs_4'
                            '4.9.1'
                          else
                            '8.12.0'
                          end

default['nodejs']['version'] = node.engineyard.environment.metadata('nodejs_version', fallback_nodejs_version)
