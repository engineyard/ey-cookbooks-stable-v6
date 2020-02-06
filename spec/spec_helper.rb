require 'chefspec'

require_relative 'dna/dna_helper'

def create_chef_runner
  ChefSpec::SoloRunner.new do |node|
    if block_given?
      DNASpec::set_dnapi_environment(node) do |environment|
        yield environment
      end
    else
      DNASpec::set_dnapi_environment(node)
    end
  end
end

RSpec.configure do |config|
  config.platform = 'ey-ubuntu'
  config.version = '18.04.0.9'
  config.cookbook_path = File.expand_path('../../cookbooks', __FILE__)
end

at_exit { ChefSpec::Coverage.report! }
