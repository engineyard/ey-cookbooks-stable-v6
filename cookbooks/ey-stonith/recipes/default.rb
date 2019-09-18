if ["app_master", "app"].include?(node['dna']['instance_role'])
  file "/etc/stonith.yml" do
    owner 'root'
    group 'root'
    mode 0644
    content node.engineyard.instance.stonith_config.to_hash.to_yaml
  end

  logrotate "ey-stonith" do
    files "/var/log/stonith.log /var/log/stonith-cron.log"
    copy_then_truncate true
  end
end
