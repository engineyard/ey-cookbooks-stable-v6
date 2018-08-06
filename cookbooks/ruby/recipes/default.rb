directory "/tmp/src" do
  owner "root"
  group "root"
  mode '0755'
end

execute "extract-chruby" do
  command "tar xzf /tmp/src/chruby-0.3.9.tar.gz && cd chruby-0.3.9 && make install"
  cwd "/tmp/src"
  action :nothing
end

remote_file "/tmp/src/chruby-0.3.9.tar.gz" do
  source "https://github.com/postmodern/chruby/archive/v0.3.9.tar.gz"
  owner "root"
  group "root"
  mode '0644'
  action :create
  notifies :run, "execute[extract-chruby]", :immediately
end

execute "extract-ruby-install" do
  command "tar xzf /tmp/src/ruby-install-0.7.0.tar.gz && cd ruby-install-0.7.0 && make install"
  cwd "/tmp/src"
  action :nothing
end

remote_file "/tmp/src/ruby-install-0.7.0.tar.gz" do
  source "https://github.com/postmodern/ruby-install/archive/v0.7.0.tar.gz"
  owner "root"
  group "root"
  mode '0755'
  action :create
  notifies :run, "execute[extract-ruby-install]", :immediately
end

ruby_version = node[:ruby][:version]
template "/etc/profile.d/chruby.sh" do
  source "chruby.sh.erb"
  owner "root"
  group "root"
  mode '0644'
  variables ruby_version: ruby_version
  action :create
end

bash "install ruby" do
  code <<-EOH
    source /usr/local/share/chruby/chruby.sh
    chruby #{ruby_version}
    if [ "$(ruby -v)" ]
    then
      echo "Ruby #{ruby_version} is already installed. Skipping Ruby installation"
    else
      echo "Installing Ruby #{ruby_version}"
      ruby-install ruby #{ruby_version}
    fi
  EOH
end

ruby_block "add ruby path during chef run" do
  block { ENV['PATH'] = "/opt/rubies/ruby-#{ruby_version}/bin:#{ENV['PATH']}" }
end

execute "test ruby" do
  command "echo ruby is installed"
  only_if "ruby -v"
end
