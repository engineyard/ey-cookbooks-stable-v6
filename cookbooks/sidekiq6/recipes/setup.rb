#
# Cookbook Name:: sidekiq6
# Recipe:: setup
#

if node['sidekiq']['is_sidekiq_instance']
  # report to dashboard
  ey_cloud_report "sidekiq6" do
    message "Setting up sidekiq 6 or later"
  end

  # loop through applications
  node['dna']['applications'].each do |app_name, _|
    node['sidekiq']['workers'].times do |count|
      execute "restart-sidekiq-for-#{app_name}-#{count}" do
        command "systemctl daemon-reload && systemctl restart sidekiq_#{app_name}_#{count}"
        action :nothing
        only_if "test -f '/lib/systemd/system/sidekiq_#{app_name}_#{count}.service'"
      end

    # set up systemd
      template "/lib/systemd/system/sidekiq_#{app_name}_#{count}.service" do
        mode 0644
        source "sidekiq.service.erb"
        backup false
        variables({
          :app_name => app_name,
          :count => count,
          :rails_env => node['dna']['environment']['framework_env'],
          :memory_limit => node['sidekiq']['worker_memory']
        })
        notifies :run, "execute[restart-sidekiq-for-#{app_name}-#{count}]"
      end
    end

    execute "set-up-variables-for-sidekiq" do
      command "cat /data/#{app_name}/shared/config/env.cloud |tr -d '\"' |awk '{gsub(\"export \", \"\");print}' > /data/#{app_name}/shared/config/env.sidekiq.cloud"
    end
    # database.yml
    execute "update-database-yml-pg-pool-for-#{app_name}" do
      db_yaml_file = "/data/#{app_name}/shared/config/database.yml"
      command "sed -ibak --follow-symlinks 's/reconnect/pool:      #{node['sidekiq']['concurrency']}\\\n  reconnect/g' #{db_yaml_file}"
      action :run
      only_if "test -f #{db_yaml_file} && ! grep 'pool: *#{node['sidekiq']['concurrency']}' #{db_yaml_file}"
      node['sidekiq']['workers'].times do |count|
        notifies :run, "execute[restart-sidekiq-for-#{app_name}-#{count}]"
      end
    end

    # yml files
    node['sidekiq']['workers'].times do |count|
      template "/data/#{app_name}/shared/config/sidekiq_#{count}.yml" do
        owner node['owner_name']
        group node['owner_name']
        mode 0644
        source "sidekiq.yml.erb"
        backup false
        variables(node['sidekiq'])
        notifies :run, "execute[restart-sidekiq-for-#{app_name}-#{count}]"
      end
      link "/data/#{app_name}/current/config/sidekiq_#{count}.yml" do
        to "/data/#{app_name}/shared/config/sidekiq_#{count}.yml"
      end
    end

    # chown log files
    node['sidekiq']['workers'].times do |count|
      file "/data/#{app_name}/shared/log/sidekiq_#{count}.log" do
        owner node['owner_name']
        group node['owner_name']
        action :touch
      end
    end
  end
end

if node['sidekiq']['create_restart_hook']
  # loop through applications
  node['dna']['applications'].each do |app_name, _|
    directory "/data/#{app_name}/shared/hooks/sidekiq" do
      owner node["owner_name"]
      group node["owner_name"]
      mode 0755
      recursive true
    end

    # after_restart hook
    template "/data/#{app_name}/shared/hooks/sidekiq/after_restart" do
      mode 0755
      source "after_restart.erb"
      backup false
      variables({
        :workers => node['sidekiq']['workers'],
        :app_name => app_name,
        :is_sidekiq_instance => node['sidekiq']['is_sidekiq_instance']
      })
    end
  end
end
