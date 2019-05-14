unattended_flag = 0

node['dna']['engineyard']['environment']['apps'].each do |app_data|

  environment_variables = fetch_environment_variables(app_data)

  environment_variables.each do |variable|
    if variable[:name] == 'EY_ENABLE_UNATTENDED_UPGRADES' && variable[:value] == 'true'
      unattended_flag = 1
    end
  end
end

template "/etc/apt/apt.conf.d/20auto-upgrades" do
  mode 0644
  source "auto-upgrades.erb"
  backup false
  variables({
    :unattended_flag => unattended_flag
  })
end
