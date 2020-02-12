# Report to Cloud dashboard
ey_cloud_report "processing php" do
  message "processing php - install"
end

version = node["php"]["minor_version"]

execute "add repository" do
  command "add-apt-repository ppa:ondrej/php"
  not_if { File.exist?("/etc/apt/sources.list.d/ondrej-ubuntu-php-bionic.list") }
end

package "php#{version}" do
  action :upgrade
end
package "apache2" do
  action :remove
end
package "PHP #{version} extensions" do
  action :upgrade
  package_name ["php#{version}-bcmath", "php#{version}-bz2", "php#{version}-curl",
                "php#{version}-dba", "php#{version}-gd", "php#{version}-imap",
                "php#{version}-intl", "php#{version}-mbstring", "php#{version}-mysql",
                "php#{version}-pgsql", "php#{version}-pspell", "php#{version}-snmp",
                "php#{version}-soap", "php#{version}-sqlite3", "php#{version}-tidy",
                "php#{version}-xml", "php#{version}-xmlrpc", "php#{version}-xsl",
                "php#{version}-zip"
               ]
end

extra_extensions = (fetch_env_var(node, "EY_PHP_EXTRA_EXTENSIONS") || '')
  .split(',').map(&:strip).select { |x| !x.empty? }
if extra_extensions.length > 0
  package "PHP #{version} extensions" do
    action :upgrade
    package_name extra_extensions.map { |x| "php#{version}-#{x}" }
  end
end
