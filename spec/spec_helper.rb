require 'chefspec'

require_relative 'dna/dna_helper'

RSpec.configure do |config|
  config.platform = 'ey-ubuntu'
  config.version = '18.04.0.9'
end

at_exit { ChefSpec::Coverage.report! }
