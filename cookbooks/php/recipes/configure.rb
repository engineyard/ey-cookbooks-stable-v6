class Chef::Recipe
  include PhpHelpers
end

version = node["php"]["minor_version"]
php_ini = get_php_ini_cbfilename

cookbook_file "/etc/php/#{version}/cli/php.ini" do
  source php_ini
  owner "root"
  group "root"
  mode "0755"
  backup 0
end
