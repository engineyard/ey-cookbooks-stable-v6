require 'pp'
Chef::Log.info(ENV.pretty_inspect)

include_recipe "ey-base::bootstrap"
include_recipe "app::prep"
include_recipe "app::build"
