require 'spec_helper'

describe 'mysql::default' do
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
    runner.converge(described_recipe)
  }

  context 'in a MySQL 8.0 environment' do
    let(:db_stack) { DNApi::DbStack::Mysql8_0 }
    it 'writes the MySQL configuration file' do
      expect(chef_run).to create_managed_template('/etc/mysql/percona-server.cnf')
    end

    it 'sets the my.cnf alternative' do
      expect(chef_run).to run_bash('Set my.cnf alternatives')
    end
  end

  context 'in a MySQL 5.7 environment' do
    let(:db_stack) { DNApi::DbStack::Mysql5_7 }
    it 'writes the MySQL configuration file' do
      expect(chef_run).to create_managed_template('/etc/mysql/percona-server.cnf')
    end
    
    it 'sets the my.cnf alternative' do
      expect(chef_run).to run_bash('Set my.cnf alternatives')
    end
  end
end
