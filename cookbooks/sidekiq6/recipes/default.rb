#
# Cookbook Name:: sidekiq6
# Recipe:: default
#

include_recipe "sidekiq6::cleanup"
include_recipe "sidekiq6::setup"
