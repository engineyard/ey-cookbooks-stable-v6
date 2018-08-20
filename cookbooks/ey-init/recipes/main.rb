require 'pp'
Chef::Log.info(ENV.pretty_inspect)

include_recipe "ey-base::resin_gems"
include_recipe "logrotate" # move to ey-core
include_recipe "ey-base::bootstrap"
include_recipe "db_master::prep"
include_recipe "app::prep"
include_recipe "lb::prep"
include_recipe "db_master::build"
include_recipe "app::build"
include_recipe "lb::build"
include_recipe "nodejs::common" # move to post_bootstrap
