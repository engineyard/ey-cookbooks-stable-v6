default['elasticsearch'].tap do |elasticsearch|
  # Run Elasticsearch on util instances containing elasticsearch in name
  # This is the default
  elasticsearch['instance_name'] = 'elasticsearch'
  elasticsearch['is_elasticsearch_instance'] = (
    node.dna['instance_role'] == 'util' &&
    node.dna['name'].include?(elasticsearch['instance_name'])
  )

  # Run Elasticsearch on a solo or app_master instance
  # Not recommended for production environments
  #elasticsearch['is_elasticsearch_instance'] = ( ['solo', 'app_master'].include?(node.dna['instance_role']) )

  # Elasticsearch version to install
  # Go to https://www.elastic.co/downloads/past-releases to see the available version
  #elasticsearch['version'] = '5.6.15'
  elasticsearch['version'] = '6.6.2'
  
  # Elasticsearch cluster name
  elasticsearch['clustername'] = node.dna['environment']['name']

  # Where to store the ES index
  elasticsearch['home'] = '/data/elasticsearch'

  # Elasticsearch configuration parameters
  elasticsearch['heap_size'] = 1000
  elasticsearch['fdulimit'] = nil
  elasticsearch['defaultreplicas'] = 1
  elasticsearch['defaultshards'] = 6

  # JVM Options, will be used to populate /etc/elasticsearch/jvm.options
  # For guidelines on how to calculate the optimal JVM memory settings,
  # see https://www.elastic.co/guide/en/elasticsearch/reference/master/heap-size.html
  elasticsearch['jvm_options'] = {
    :Xms => '2g',
    :Xmx => '2g',
    :Xss => '1m'
  }
end
