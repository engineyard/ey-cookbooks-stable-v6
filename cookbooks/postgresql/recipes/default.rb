postgres_version = node['postgresql']['short_version']

if ['solo', 'db_master', 'db_slave'].include?(node.dna['instance_role'])
  ey_cloud_report "start postgresql run" do
    message "processing postgresql #{postgres_version}"
  end
  include_recipe "ebs::default"
  #TODOv6 include_recipe "postgresql::client_config"
  include_recipe "postgresql::server_install"
  include_recipe "postgresql::server_configure"
  #TODOv6 include_recipe "postgresql::monitoring"
  #TODOv6  include_recipe "postgresql::relink_postgresql"
  ey_cloud_report "stop postgresql run" do
    message "processing postgresql #{postgres_version} finished"
  end
end
if ['app_master', 'app', 'util'].include?(node.dna['instance_role'])
  ey_cloud_report "start postgresql run" do
    message "processing postgresql #{postgres_version}"
  end
  include_recipe "postgresql::client_config"
  include_recipe "postgresql::server_install"
  include_recipe "postgresql::relink_postgresql"
  ey_cloud_report "stop postgresql run" do
    message "processing postgresql #{postgres_version} finished"
  end
end

if (db_host_is_rds? && node.dna[:instance_role] == 'app_master') || (!db_host_is_rds? && ['solo', 'db_master', 'eylocal'].include?(node.dna[:instance_role]))
  #TODOv6 include_recipe "postgresql::setup_app_users_dbs"
end
