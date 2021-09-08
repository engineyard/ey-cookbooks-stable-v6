letsencrypt = node['letsencrypt']

package "python3-pip" do
  action :install
end

execute "ensure pip3 is up-to-date" do
  command "pip3 install pip --upgrade"
end

execute "install certbot" do
  command "pip3 install certbot"
end

md = fetch_env_var(node, 'EY_LE_DOMAINS').split[0]  #= fetch_env_var(node, 'EY_LE_MAIN_DOMAIN').downcase
domain = fetch_env_var(node, 'EY_LE_DOMAINS').nil? || (fetch_env_var(node, 'EY_LE_DOMAINS').gsub(" "," -d ")).downcase
app = fetch_env_var(node, 'EY_LE_MAIN_APP_NAME') || node['dna']['applications'].keys.first
wc = fetch_env_var(node, 'EY_LE_USE_WILDCARD') || false
type = fetch_env_var(node, 'EY_LE_DNS_TYPE') || ""

Chef::Log.info "LetsEncrypt Widlcard: #{wc}"

if Dir.exist?("/data/#{app}/current") && ['solo', 'app_master'].include?(node['dna']['instance_role'])
 
  execute "force start haproxy / nginx" do
    command "/etc/init.d/haproxy start /etc/init.d/nginx start"
  end 

  if wc

    execute "Install plugin for certbot" do
      command "pip3 install certbot-dns-#{type}"
    end

    managed_template "/opt/.letsencrypt-secrets" do
      mode 0700
      source "letsencrypt.secrets.erb"
      variables(
        :data => fetch_env_var(node, 'EY_LE_DNS_AUTH_INFO')
      )
    end

    execute "Issue certiciate initially" do
      command "certbot certonly --dns-#{type} --dns-#{type}-credentials /opt/.letsencrypt-secrets -d #{domain} --non-interactive --agree-tos --register-unsafely-without-email --dry-run"
      not_if { File.exist?("/etc/letsencrypt/live/#{md}/privkey.pem") }
    end

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
      :instances => (node.cluster - node.db_slaves - node.db_master - node.util_servers).join(' '),
      :md => md
    )
  end

  managed_template "/engineyard/bin/check_le.sh" do
    owner 'deploy'
    group 'deploy'
    mode 0700
    source 'check_le.sh.erb'
    variables(
    :md => md
    )
  end
  execute "update collectd" do
    command 'sed -i \'81 i \ \ Exec \"deploy\" \"/engineyard/bin/check_le.sh\"\' /etc/engineyard/collectd.conf && /etc/init.d/collectd restart'
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
