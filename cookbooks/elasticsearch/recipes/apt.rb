ES = node.elasticsearch
es_version_series = "#{ES['version'][0]}.x"

if ES['is_elasticsearch_instance']
  Chef::Log.info "Setting up the Elasticsearch #{es_version_series} APT repository"

  execute "apt-get update for elasticsearch-#{es_version_series}" do
    command "apt-get update"
    action :nothing
  end

  apt_repository "elasticsearch-#{es_version_series}" do
    uri "https://artifacts.elastic.co/packages/#{es_version_series}/apt"
    key 'https://artifacts.elastic.co/GPG-KEY-elasticsearch'
    components ['stable', 'main']
    action :add
    notifies :run, "execute[apt-get update for elasticsearch-#{es_version_series}]", :immediately
  end
end
