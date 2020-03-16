require 'spec_helper'

describe 'php::default' do
  def setup_environment(environment)
    DNASpec.build_instance(environment, :solo)
    environment.stack = DNApi::Stack::NginxPHP
    app = environment.build_app(name: 'testapp')
    environment.add_component(:php_73)
  end
  def get_this_instance(environment)
    environment.instances[0]
  end
  let(:chef_run) {
    runner = create_chef_runner do |environment|
      setup_environment(environment)
      get_this_instance(environment)
    end
    runner.converge(described_recipe) do
      runner.resource_collection.insert(
        Chef::Resource::Execute.new('reload-systemd', runner.run_context))
    end
  }

  context 'in a solo environment' do
    it { expect(chef_run).to include_recipe('php::install') }
    it { expect(chef_run).to include_recipe('php::configure') }
    it { expect(chef_run).to include_recipe('php::composer') }
    it { expect(chef_run).to include_recipe('php::fpm') }
  end

  context 'in a multi-instance environment' do
    def setup_environment(environment)
      DNASpec::build_instance(environment, :app_master)
      DNASpec::build_instance(environment, :app)
      DNASpec::build_instance(environment, :db_master)
      DNASpec::build_instance(environment, :util, { :name => 'memcached' })
      environment.stack = DNApi::Stack::NginxPHP
      app = environment.build_app(name: 'testapp')
      environment.add_component(:php_73)
    end

    context 'on the app_master' do
      def get_this_instance(environment)
        environment.app_master
      end

      it { expect(chef_run).to include_recipe('php::install') }
      it { expect(chef_run).to include_recipe('php::configure') }
      it { expect(chef_run).to include_recipe('php::composer') }
      it { expect(chef_run).to include_recipe('php::fpm') }
    end

    context 'on the app_master' do
      def get_this_instance(environment)
        environment.db_master
      end

      it { expect(chef_run).to include_recipe('php::install') }
      it { expect(chef_run).to include_recipe('php::configure') }
      it { expect(chef_run).to include_recipe('php::composer') }
      it { expect(chef_run).not_to include_recipe('php::fpm') }
    end

    context 'on the util' do
      def get_this_instance(environment)
        environment.utility_instances.detect {|i| i.name == 'memcached' }
      end

      it { expect(chef_run).to include_recipe('php::install') }
      it { expect(chef_run).to include_recipe('php::configure') }
      it { expect(chef_run).to include_recipe('php::composer') }
      it { expect(chef_run).not_to include_recipe('php::fpm') }
    end
  end
end
