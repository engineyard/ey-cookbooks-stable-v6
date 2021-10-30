#
# Cookbook Name:: sidekiq
# Recipe:: default
#

include_recipe "sidekiq6::cleanup"
include_recipe "sidekiq6::setup"
