require 'spec_helper'
require_relative '../libraries/php_helpers'

RSpec.configure do |c|
  c.include PhpHelpers
end

describe 'php::configure' do
  let(:php_version) { :php_73 }
  def setup_environment(environment, php_version)
    DNASpec.build_instance(environment, :solo)
    environment.stack = DNApi::Stack::NginxPHP
    app = environment.build_app(name: 'testapp')
    environment.add_component(php_version)
  end
  def get_this_instance(environment)
    environment.instances[0]
  end
  let(:chef_run) {
    runner = create_chef_runner do |environment|
      setup_environment(environment, php_version)
      get_this_instance(environment)
    end
    runner.converge(described_recipe)
  }

  [:php_71, :php_72, :php_73, :php_74].each do |php_version|
    context "in a #{php_version} environment" do
      let(:node) { chef_run.node }
      let(:php_version_str) { node['php']['version'] }

      it 'writes a config file' do
        expect(chef_run).to create_cookbook_file("/etc/php/#{php_version_str}/cli/php.ini").with(
          source: get_php_ini_cbfilename
        )
        expect(chef_run).to render_file("/etc/php/#{php_version_str}/cli/php.ini")
      end
    end
  end
end
