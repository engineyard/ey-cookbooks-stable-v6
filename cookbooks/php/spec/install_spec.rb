require 'spec_helper'

describe 'php::install' do
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
      let(:php_version) { php_version }
      let(:php_version_str) { chef_run.node['php']['version'] }
      let(:php_pkg_prefix) { "php#{php_version_str}" }

      it { expect(chef_run).to upgrade_package("#{php_pkg_prefix}") }
      it { expect(chef_run).to remove_package("apache2") }

      it 'installs PHP extensions' do
        expect(chef_run).to upgrade_package("PHP #{php_version_str} extensions").with(
          package_name: [
            "bcmath", "bz2", "curl", "dba", "gd", "imap", "intl", "mbstring", "mysql",
            "pgsql", "pspell", "snmp", "soap", "sqlite3", "tidy",
            "xml", "xmlrpc", "xsl", "zip"
          ].map { |x| "#{php_pkg_prefix}-#{x}" }
        )
      end
    end
  end
end
