#
# Cookbook Name:: elasticsearch
# Recipe:: default
#
# Credit goes to GoTime for their original recipe ( http://cookbooks.opscode.com/cookbooks/elasticsearch )

ES = node.elasticsearch

include_recipe 'elasticsearch::apt'
include_recipe 'elasticsearch::install'
if ES['is_elasticsearch_instance']
  # TODO jf
  include_recipe 'elasticsearch::configure_cluster'
  # TODO jf
  include_recipe 'elasticsearch::configure_limits'
end
