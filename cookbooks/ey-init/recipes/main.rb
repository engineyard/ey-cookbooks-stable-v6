require 'pp'
Chef::Log.info(ENV.pretty_inspect)

include_recipe "ey-base::resin_gems"
include_recipe "ey-core"

include_recipe 'ey-custom::before-main'
include_recipe "ey-base::bootstrap"
#node.engineyard.instance.roles.each { |role| include_recipe "#{role}::prep" }
#node.engineyard.instance.roles.each { |role| include_recipe "#{role}::build" }
#include_recipe "ey-base::post_bootstrap"
include_recipe "ey-base::custom"
include_recipe 'ey-custom::after-main'
