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

env_var_ruby = fetch_env_var(node, "EY_RUBY_VERSION")
ruby_version = env_var_ruby.nil? ? node[:ruby][:version] : env_var_ruby
log "Setting Ruby version to #{ruby_version}"

template "/etc/profile.d/chruby.sh" do
  source "chruby.sh.erb"
  owner "root"
  group "root"
  mode '0644'
  variables ruby_version: ruby_version
  action :create
end

include_recipe "ruby::dependencies"

bash "install ruby" do
  code <<-EOH
    if [ -e /opt/rubies/ruby-#{ruby_version}/bin/ruby ]
    then
      echo "Ruby #{ruby_version} is already installed. Skipping Ruby installation"
    else
      echo "Installing Ruby #{ruby_version}"
      mkdir -p /opt/rubies
      chown -R #{node['owner_name']}:#{node['owner_name']} /opt/rubies
      sudo -u #{node['owner_name']} ruby-install --no-install-deps -r /opt/rubies ruby #{ruby_version}
    fi
  EOH
end

execute "chown /opt/rubies" do
  command "chown -R #{node['owner_name']}:#{node['owner_name']} /opt/rubies"
end

ruby_block "add ruby path during chef run" do
  block { ENV['PATH'] = "/opt/rubies/ruby-#{ruby_version}/bin:#{ENV['PATH']}" }
end

include_recipe "ruby::rubygems"
