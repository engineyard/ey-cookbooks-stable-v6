require 'spec_helper'

describe 'sidekiq::setup' do
  def setup_environment(environment)
    instance = DNASpec::build_instance(environment, :solo)
    environment.stack = DNApi::Stack::NginxUnicorn
    app = environment.build_app(name: 'testapp')
    DNASpec::set_app_environment_variables(app, [
      { :name => 'EY_SIDEKIQ_ENABLED', :value => 'true' }
    ])
  end
  def get_this_instance(environment)
    environment.instances[0]
  end
  before do
    stub_command("pgrep -f sidekiq").and_return(true)
    stub_command("test -f /data/testapp/shared/config/database.yml && ! grep 'pool: *25' /data/testapp/shared/config/database.yml").and_return(true)
  end
  let(:chef_run) {
    runner = create_chef_runner do |environment|
      setup_environment(environment)
      get_this_instance(environment)
    end
    runner.converge(described_recipe) do
      runner.resource_collection.insert(
        Chef::Resource::Execute.new('reload-monit', runner.run_context))
    end
  }

  it 'places a sidekiq executable' do
    expect(chef_run).to create_cookbook_file('/engineyard/bin/sidekiq').with(
      mode: 0755,
      backup: false
    )
    expect(chef_run).to render_file('/engineyard/bin/sidekiq')
  end

  it 'writes a monit config' do
    expect(chef_run).to render_file('/etc/monit.d/sidekiq_testapp.monitrc').with_content { |content|
      expect(content).to include('group testapp_sidekiq')
      expect(content).to include('check process sidekiq_testapp_0')
    }
    expect(chef_run.template('/etc/monit.d/sidekiq_testapp.monitrc')).to notify('execute[restart-sidekiq-for-testapp]').to(:run)
  end

  context 'in a multi-instance environment' do
    def setup_environment(environment)
      DNASpec::build_instance(environment, :app_master)
      DNASpec::build_instance(environment, :app)
      DNASpec::build_instance(environment, :db_master)
      DNASpec::build_instance(environment, :util, { :name => 'sidekiq1' })
      environment.stack = DNApi::Stack::NginxUnicorn
      app = environment.build_app(name: 'testapp')
      DNASpec::set_app_environment_variables(app, [
        { :name => 'EY_SIDEKIQ_ENABLED', :value => 'true' },
        { :name => 'EY_SIDEKIQ_INSTANCES_ROLE', :value => 'util' },
        { :name => 'EY_SIDEKIQ_INSTANCES_NAME', :value => '^sidekiq(\d+)$' },
      ])
    end

    context 'on the app_master' do
      def get_this_instance(environment)
        environment.app_master
      end

      it 'creates a noop after_restart hook' do
        expect(chef_run).to render_file('/data/testapp/shared/hooks/sidekiq/after_restart').with_content { |content|
          expect(content).not_to include('sudo monit -g testapp_sidekiq restart all')
          expect(content).to include('exit 0')
        }
      end
    end

    context 'on the util[sidekiq1]' do
      def get_this_instance(environment)
        environment.utility_instances.detect {|i| i.name == 'sidekiq1' }
      end

      it 'creates a proper after_restart hook' do
        expect(chef_run).to render_file('/data/testapp/shared/hooks/sidekiq/after_restart').with_content { |content|
          expect(content).to include('sudo monit -g testapp_sidekiq restart all')
        }
      end
    end
  end

  context 'sidekiq is not enabled' do
    def setup_environment(environment)
      instance = DNASpec::build_instance(environment, :solo)
      environment.stack = DNApi::Stack::NginxUnicorn
      app = environment.build_app(name: 'testapp')
      DNASpec::set_app_environment_variables(app, [
        { :name => 'EY_SIDEKIQ_ENABLED', :value => 'false' }
      ])
    end

    it 'doesn\'t place a sidekiq executable' do
      expect(chef_run).not_to create_cookbook_file('/engineyard/bin/sidekiq')
    end

    it 'doesn\'t write a monit config' do
      expect(chef_run).not_to render_file('/etc/monit.d/sidekiq_testapp.monitrc')
    end
    
    it 'doesn\'t create an after_restart hook' do
      expect(chef_run).not_to render_file('/data/testapp/shared/hooks/sidekiq/after_restart')
    end
  end
end
