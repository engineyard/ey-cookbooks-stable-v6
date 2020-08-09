letsencrypt = node['letsencrypt']

package "certbot" do
  action :install
end

md = fetch_env_var(node, 'EY_LE_MAIN_DOMAIN')
domain = fetch_env_var(node, 'EY_LE_DOMAINS').nil? || (fetch_env_var(node, 'EY_LE_DOMAINS').gsub(" "," -d "))
app = fetch_env_var(node, 'EY_LE_MAIN_APP_NAME') || node['dna']['applications'].keys.first
wc = fetch_env_var(node, 'EY_LE_USE_WILDCARD') || false

if Dir.exist?("/data/#{app}/current") && ['solo', 'app_master'].include?(node['dna']['instance_role'])
 
  execute "force start haproxy / nginx" do
    command "/etc/init.d/haproxy start /etc/init.d/nginx start"
  end 

if !wc

  execute "issue certificate" do
    command "certbot certonly --noninteractive --agree-tos --register-unsafely-without-email -d #{domain} --webroot -w /data/#{app}/current/public/"
    not_if { ::Dir.exist? ("/etc/letsencrypt/live/#{md}/") }
  end
end 

  managed_template "/engineyard/bin/copycerts.sh" do
    owner 'root'
    group 'root'
    mode 0700
    source "copycerts.sh.erb"
    variables(   
      :app_name => app,
      :instances => (node.cluster - node.db_slaves - node.db_master).join(' '),
      :md => md
    )
  end

  execute "push certificate" do
    command "/engineyard/bin/copycerts.sh" 
  end

  cron "renew certificates" do 
    command "bash -c '/engineyard/bin/copycerts.sh'"
    day '1,15,29'
    hour '0'
    minute '0'
  end
end
