require 'pp'
Chef::Log.info(ENV.pretty_inspect)

include_recipe "ey-base::bootstrap"
include_recipe "db_master::prep"
include_recipe "app::prep"
include_recipe "app::build"
include_recipe "nodejs::common" # move to post_bootstrap
