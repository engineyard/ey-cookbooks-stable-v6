require 'spec_helper'

describe 'attributes' do
  before do
    allow_any_instance_of(Chef::Recipe).to receive(:include_recipe).with('ebs::default')
    allow_any_instance_of(Chef::Recipe).to receive(:`).with('ifconfig eth0').and_return('inet 10.0.8.21')
    allow_any_instance_of(Chef::Recipe).to receive(:`).with('cat /proc/meminfo').and_return('MemTotal:        7808032 kB')
    stub_command("grep -qs '/etc/mysql.d' /etc/fstab").and_return(true)
  end
  let(:db_stack) { DNApi::DbStack::Mysql8_0 }
  def setup_environment(environment)
    DNASpec.build_instance(environment, :solo)
    environment.stack = DNApi::Stack::NginxUnicorn
    environment.db_stack = db_stack
    app = environment.build_app(name: 'testapp')
    environment.add_component(:ruby_260)
  end
  def get_this_instance(environment)
    environment.instances[0]
  end
  let(:chef_run) {
    runner = create_chef_runner do |environment|
      setup_environment(environment)
      get_this_instance(environment)
    end
    runner.converge('recipe[mysql]')
  }
  let(:attributes) { chef_run.node['mysql'] }

  context 'in a MySQL 5.6 environment' do
    let(:db_stack) { DNApi::DbStack::Mysql5_6 }

    it { expect(attributes['latest_version']).to eq('5.6.44') }
    it { expect(attributes['short_version']).to eq('5.6') }
    it { expect(attributes['logbase']).to eq('/db/mysql/5.6/log/') }
    it { expect(attributes['datadir']).to eq('/db/mysql/5.6/data/') }
    it { expect(attributes['ssldir']).to eq('/db/mysql/5.6/ssl/') }
  end

  context 'in a MySQL 5.7 environment' do
    let(:db_stack) { DNApi::DbStack::Mysql5_7 }

    it { expect(attributes['latest_version']).to eq('5.7.26') }
    it { expect(attributes['short_version']).to eq('5.7') }
    it { expect(attributes['logbase']).to eq('/db/mysql/5.7/log/') }
    it { expect(attributes['datadir']).to eq('/db/mysql/5.7/data/') }
    it { expect(attributes['ssldir']).to eq('/db/mysql/5.7/ssl/') }
  end

  context 'in a MySQL 8.0 environment' do
    let(:db_stack) { DNApi::DbStack::Mysql8_0 }

    it { expect(attributes['latest_version']).to eq('8.0.18') }
    it { expect(attributes['short_version']).to eq('8.0') }
    it { expect(attributes['logbase']).to eq('/db/mysql/8.0/log/') }
    it { expect(attributes['datadir']).to eq('/db/mysql/8.0/data/') }
    it { expect(attributes['ssldir']).to eq('/db/mysql/8.0/ssl/') }
  end
end
