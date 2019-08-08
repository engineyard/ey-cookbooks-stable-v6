#
# Cookbook Name:: env_vars
# Recipe:: init
#

if ['solo', 'app', 'app_master', 'util'].include?(node['dna']['instance_role'])

  ssh_username = node['dna']['engineyard']['environment']['ssh_username']

  node['dna']['applications'].each do |app_name, data|
    template "/data/#{app_name}/shared/config/env.custom" do
      source "env.custom.erb"
      owner ssh_username
      group ssh_username
      mode 0744
      not_if { File.exists?("/data/#{app_name}/shared/config/env.custom")}

    end
  end

end
