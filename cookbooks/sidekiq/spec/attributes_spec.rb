require 'spec_helper'

describe 'attributes' do
  def setup_environment(environment)
    DNASpec::build_instance(environment, :solo)
  end
  def get_this_instance(environment)
    environment.instances[0]
  end
  before do
    stub_command("pgrep -f sidekiq").and_return(true)
    stub_command("test -f /data//shared/config/database.yml && ! grep 'pool: *25' /data//shared/config/database.yml").and_return(true)
  end
  let(:chef_run) {
    runner = create_chef_runner do |environment|
      setup_environment(environment)
      get_this_instance(environment)
    end
    runner.converge('recipe[sidekiq]') do
      runner.resource_collection.insert(
        Chef::Resource::Execute.new('reload-monit', runner.run_context))
    end
  }
  let(:attributes) { chef_run.node['sidekiq'] }

  context 'default' do
    it { expect(attributes['is_sidekiq_instance']).to be false }
    it { expect(attributes['create_restart_hook']).to be false }
    it { expect(attributes['workers']).to eq(1) }
    it { expect(attributes['concurrency']).to eq(25) }
    it { expect(attributes['queues']).to eql({ 'default' => 1 }) }
    it { expect(attributes['worker_memory']).to eq(400) }
    it { expect(attributes['verbose']).to be false }
    it { expect(attributes['orphan_monitor_enabled']).to be false }
    it { expect(attributes['orphan_monitor_cron_schedule']).to eq("*/5 * * * *") }
  end

  context 'enabled for util[sidekiq1]' do
    def setup_environment(environment)
      DNASpec::build_instance(environment, :app_master)
      DNASpec::build_instance(environment, :app)
      DNASpec::build_instance(environment, :db_master)
      DNASpec::build_instance(environment, :db_slave, { :name => 'slave1' })
      DNASpec::build_instance(environment, :util, { :name => 'sidekiq1' })
      environment.stack = DNApi::Stack::NginxUnicorn
      app = environment.build_app
      DNASpec::set_app_environment_variables(app, [
        { :name => 'EY_SIDEKIQ_ENABLED', :value => 'true' },
        { :name => 'EY_SIDEKIQ_INSTANCES_ROLE', :value => 'util' },
        { :name => 'EY_SIDEKIQ_INSTANCES_NAME', :value => '^sidekiq(\d+)$' },
      ])
    end

    context 'on app_master' do
      def get_this_instance(environment)
        environment.app_master
      end

      it { expect(attributes['is_sidekiq_instance']).to be false }
      it { expect(attributes['create_restart_hook']).to be true }
    end

    context 'on db_master' do
      def get_this_instance(environment)
        environment.db_master
      end

      it { expect(attributes['is_sidekiq_instance']).to be false }
      it { expect(attributes['create_restart_hook']).to be true }
    end

    context 'on db_slave' do
      def get_this_instance(environment)
        environment.db_slaves.first
      end

      it { expect(attributes['is_sidekiq_instance']).to be false }
      it { expect(attributes['create_restart_hook']).to be true }
    end

    context 'on util[sidekiq1]' do
      def get_this_instance(environment)
        environment.utility_instances.detect {|i| i.name == 'sidekiq1' }
      end

      it { expect(attributes['is_sidekiq_instance']).to be true }
      it { expect(attributes['create_restart_hook']).to be true }
    end
  end

  context 'enabled for db' do
    def setup_environment(environment)
      DNASpec::build_instance(environment, :app_master)
      DNASpec::build_instance(environment, :app)
      DNASpec::build_instance(environment, :db_master)
      DNASpec::build_instance(environment, :db_slave, { :name => 'slave1' })
      DNASpec::build_instance(environment, :util, { :name => 'sidekiq1' })
      environment.stack = DNApi::Stack::NginxUnicorn
      app = environment.build_app
      DNASpec::set_app_environment_variables(app, [
        { :name => 'EY_SIDEKIQ_ENABLED', :value => 'true' },
        { :name => 'EY_SIDEKIQ_INSTANCES_ROLE', :value => '^db_' }
      ])
    end

    context 'on app_master' do
      def get_this_instance(environment)
        environment.app_master
      end

      it { expect(attributes['is_sidekiq_instance']).to be false }
      it { expect(attributes['create_restart_hook']).to be true }
    end

    context 'on db_master' do
      def get_this_instance(environment)
        environment.db_master
      end

      it { expect(attributes['is_sidekiq_instance']).to be true }
      it { expect(attributes['create_restart_hook']).to be true }
    end

    context 'on db_slave' do
      def get_this_instance(environment)
        environment.db_slaves.first
      end

      it { expect(attributes['is_sidekiq_instance']).to be true }
      it { expect(attributes['create_restart_hook']).to be true }
    end

    context 'on util[sidekiq1]' do
      def get_this_instance(environment)
        environment.utility_instances.detect {|i| i.name == 'sidekiq1' }
      end

      it { expect(attributes['is_sidekiq_instance']).to be false }
      it { expect(attributes['create_restart_hook']).to be true }
    end
  end

  context 'enabled for all' do
    def setup_environment(environment)
      DNASpec::build_instance(environment, :app_master)
      DNASpec::build_instance(environment, :app)
      DNASpec::build_instance(environment, :db_master)
      DNASpec::build_instance(environment, :db_slave, { :name => 'slave1' })
      DNASpec::build_instance(environment, :util, { :name => 'sidekiq1' })
      environment.stack = DNApi::Stack::NginxUnicorn
      app = environment.build_app
      DNASpec::set_app_environment_variables(app, [
        { :name => 'EY_SIDEKIQ_ENABLED', :value => 'true' }
      ])
    end

    context 'on app_master' do
      def get_this_instance(environment)
        environment.app_master
      end

      it { expect(attributes['is_sidekiq_instance']).to be true }
      it { expect(attributes['create_restart_hook']).to be true }
    end

    context 'on app instance' do
      def get_this_instance(environment)
        environment.app_slaves.first
      end

      it { expect(attributes['is_sidekiq_instance']).to be true }
      it { expect(attributes['create_restart_hook']).to be true }
    end

    context 'on db_master' do
      def get_this_instance(environment)
        environment.db_master
      end

      it { expect(attributes['is_sidekiq_instance']).to be false }
      it { expect(attributes['create_restart_hook']).to be true }
    end

    context 'on db_slave' do
      def get_this_instance(environment)
        environment.db_slaves.first
      end

      it { expect(attributes['is_sidekiq_instance']).to be false }
      it { expect(attributes['create_restart_hook']).to be true }
    end

    context 'on util[sidekiq1]' do
      def get_this_instance(environment)
        environment.utility_instances.detect {|i| i.name == 'sidekiq1' }
      end

      it { expect(attributes['is_sidekiq_instance']).to be true }
      it { expect(attributes['create_restart_hook']).to be true }
    end
  end

  context 'set queue priorities' do
    def setup_environment(environment)
      DNASpec::build_instance(environment, :solo)
      environment.stack = DNApi::Stack::NginxUnicorn
      app = environment.build_app
      DNASpec::set_app_environment_variables(app, [
        { :name => 'EY_SIDEKIQ_QUEUE_PRIORITY_default', :value => '2' },
        { :name => 'EY_SIDEKIQ_QUEUE_PRIORITY_urgent', :value => '101' }
      ])
    end

    it { expect(attributes['queues']).to eql({ 'default' => 2, 'urgent' => 101 }) }
  end
end
