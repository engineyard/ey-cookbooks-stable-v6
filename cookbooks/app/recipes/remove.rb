existing_apps = `ls /var/log/engineyard/apps/`.split

existing_apps.each do |existing_app|
  unless node['dna']['applications'].include? existing_app
    execute 'Remove files of detached apps' do
      command %Q{rm -rf /data/#{existing_app}}
    end
  end
end
