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
  let(:php_version_str) { chef_run.node['php']['version'] }
  let(:php_pkg_prefix) { "php#{php_version_str}" }

  [:php_71, :php_72, :php_73, :php_74].each do |php_version|
    context "in a #{php_version} environment" do
      let(:php_version) { php_version }

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

  context "in a PHP environment with extra extensions" do
    def setup_environment(environment, php_version)
      DNASpec.build_instance(environment, :solo)
      environment.stack = DNApi::Stack::NginxPHP
      app = environment.build_app(name: 'testapp')
      environment.add_component(php_version)
      DNASpec.set_app_environment_variables(app, [
        { :name => 'EY_PHP_EXTRA_EXTENSIONS', :value => 'redis, ampq , eio ,  ' }
      ])
    end

    it 'installs extra PHP extensions' do
      expect(chef_run).to upgrade_package("extra PHP #{php_version_str} extensions").with(
        package_name: ["redis", "ampq", "eio"].map { |x| "#{php_pkg_prefix}-#{x}" }
      )
    end
  end

  context "in a PHP environment without extra extensions" do
    def setup_environment(environment, php_version)
      DNASpec.build_instance(environment, :solo)
      environment.stack = DNApi::Stack::NginxPHP
      app = environment.build_app(name: 'testapp')
      environment.add_component(php_version)
    end

    it 'does not install extra PHP extensions' do
      expect(chef_run).not_to upgrade_package("extra PHP #{php_version_str} extensions")
    end
  end
end
