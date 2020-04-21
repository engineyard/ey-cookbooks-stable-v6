include_recipe "php::system_ruby"
include_recipe "php::install"
include_recipe "php::configure"
include_recipe "php::composer"
if ['app_master', 'app', 'solo'].include? node['dna']['instance_role'].to_s
  include_recipe "php::fpm"
end
