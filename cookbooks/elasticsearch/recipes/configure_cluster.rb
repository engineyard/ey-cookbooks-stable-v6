ES = node['elasticsearch']

if node['dna']['utility_instances'].empty?
  Chef::Log.info "No utility instances found"
else
  elasticsearch_instances = []
  elasticsearch_expected = 0
  node['dna']['utility_instances'].each do |elasticsearch|
    if elasticsearch['name'].include?("elasticsearch")
      unless node['dna']['fqdn'] == elasticsearch['hostname']
        elasticsearch_expected = elasticsearch_expected + 1
        elasticsearch_instances << "#{elasticsearch['hostname']}:9300"
      end
    end
  end

  template "/etc/elasticsearch/elasticsearch.yml" do
    source "elasticsearch.yml.erb"
    owner "elasticsearch"
    group "elasticsearch"
    variables(
      :elasticsearch_instances => elasticsearch_instances.join('", "'),
      :elasticsearch_defaultreplicas => ES['defaultreplicas'],
      :elasticsearch_expected => elasticsearch_expected,
      :elasticsearch_defaultshards => ES['defaultshards'],
      :elasticsearch_clustername => ES['clustername'],
      :elasticsearch_host => node['fqdn']
    )
    mode 0600
    backup 0
  end
end
