PAPERTRAIL_CONFIG = node['papertrail']

if PAPERTRAIL_CONFIG['is_papertrail_instance']

  directory '/etc/syslog-ng/cert.d' do
    action :create
  end

  remote_file '/etc/syslog-ng/cert.d/papertrail-bundle.tar.gz' do
    source 'https://papertrailapp.com/tools/papertrail-bundle.tar.gz'
    checksum 'be208e650e910106bc9d6c954807c875b22cd9fbe005aa59e0aad0ed13b0c6b6'
    mode '0644'
  end

  bash 'extract SSL certificates' do
    cwd '/etc/syslog-ng/cert.d'
    code <<-EOH
      tar xzf papertrail-bundle.tar.gz
      EOH
  end

  remote_file "/tmp/remote_syslog2.deb" do
    source "https://github.com/papertrail/remote_syslog2/releases/download/v#{node['papertrail']['remote_syslog_version']}/remote-syslog2_#{node['papertrail']['remote_syslog_version']}_amd64.deb"
    action :create
  end

  dpkg_package "remote_syslog2" do
    source "/tmp/remote_syslog2.deb"
  end

  template '/etc/log_files.yml' do
    source 'log_files.yml.erb'
    mode '0644'
    variables(PAPERTRAIL_CONFIG)
  end

  execute 'start or restart remote_syslog' do
    command %{/etc/init.d/remote_syslog restart}
  end

end
