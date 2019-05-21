cookbook_file "/etc/php/#{node["php"]["minor_version"]}/cli/php.ini" do
  source "php.ini"
  owner "root"
  group "root"
  mode "0755"
  backup 0
end
