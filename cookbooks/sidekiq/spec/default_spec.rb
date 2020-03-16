require 'spec_helper'

describe 'sidekiq::default' do
  before do
    stub_command("pgrep -f sidekiq").and_return(true)
    stub_command("test -f /data//shared/config/database.yml && ! grep 'pool: *25' /data//shared/config/database.yml").and_return(true)
  end
  let(:chef_run) {
    runner = create_chef_runner do |environment|
      DNASpec::build_instance(environment, :solo)
    end
    runner.converge(described_recipe) do
      runner.resource_collection.insert(
        Chef::Resource::Execute.new('reload-monit', runner.run_context))
    end
  }

  it { expect(chef_run).to include_recipe('sidekiq::setup') }
  it { expect(chef_run).to include_recipe('sidekiq::cleanup') }
end
