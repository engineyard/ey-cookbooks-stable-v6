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
  command "tar xzf /tmp/src/ruby-install-0.7.0.1.tar.gz && cd ruby-install-0.7.0.1 && make install"
  cwd "/tmp/src"
  action :nothing
end

remote_file "/tmp/src/ruby-install-0.7.0.1.tar.gz" do
  source "https://github.com/engineyard/ruby-install/archive/v0.7.0.1.tar.gz"
  owner "root"
  group "root"
  mode '0755'
  action :create
  notifies :run, "execute[extract-ruby-install]", :immediately
end

ruby_name = node[:ruby][:name]
ruby_version = node[:ruby][:version]
ruby = "#{ruby_name}-#{ruby_version}"
log "Setting Ruby version to #{ruby}"

template "/etc/profile.d/chruby.sh" do
  source "chruby.sh.erb"
  owner "root"
  group "root"
  mode '0644'
  variables ruby: ruby
  action :create
end

include_recipe "ruby::dependencies"

bash "install ruby" do
  code <<-EOH
    source /usr/local/share/chruby/chruby.sh
    if [[ ! $(chruby #{ruby} 2>&1 >/dev/null) ]]; then
      echo "Ruby #{ruby} is already installed. Skipping Ruby installation"
    else
      echo "Installing Ruby #{ruby}"
      mkdir -p /opt/rubies
      chown -R #{node['owner_name']}:#{node['owner_name']} /opt/rubies
      DEBIAN_FRONTEND=noninteractive sudo -Eu #{node['owner_name']} \
        ruby-install --no-install-deps -r /opt/rubies #{ruby_name} #{ruby_version}
    fi
  EOH
end

execute "chown /opt/rubies" do
  command "chown -R #{node['owner_name']}:#{node['owner_name']} /opt/rubies"
end

ruby_block "add ruby path during chef run" do
  block { ENV['PATH'] = "/opt/rubies/#{ruby}/bin:#{ENV['PATH']}" }
end

# Add gemrc for the root user
cookbook_file "/root/.gemrc" do
  source "gemrc"
end

include_recipe "ruby::rubygems"
