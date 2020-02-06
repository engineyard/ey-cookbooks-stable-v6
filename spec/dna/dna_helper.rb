require 'dnapi'
require 'base64'

class DNASpec
  def self.build_instance(environment, role, extra_opts = {})
    id = environment.instances.length + 1
    environment.build_instance({
      :id               => id,
      :public_hostname  => "public_host.#{id}",
      :private_hostname => "private_host.#{id}",
      :role             => role
    }.merge(extra_opts))
  end

  def self.set_app_environment_variables(app, env_vars)
    env_vars = env_vars.map do |var|
      var[:value] = ::Base64.strict_encode64(var[:value])
      var
    end
    app.add_component(:app_metadata, environment_variables: env_vars)
  end

  def self.set_dnapi_environment(node)
    environment = DNApi.build
    if block_given?
      instance = yield environment
    else
      instance = build_instance(environment, :solo)
    end
    node.normal['dna'] = instance.to_dna
  end
end
