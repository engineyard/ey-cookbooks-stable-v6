# Report to Cloud dashboard
ey_cloud_report "processing php" do
  message "processing php - install"
end

version = node["php"]["minor_version"]
version_without_dot = version.delete(".")

# execute "add repository" do
#   command "add-apt-repository ppa:ondrej/php"
#   not_if { File.exist?("/etc/apt/sources.list.d/ondrej-ubuntu-php-bionic.list") }
# end

execute "add repository sergey-dryabzhinsky/php#{version_without_dot}" do
  command "add-apt-repository ppa:sergey-dryabzhinsky/php74"
  not_if { File.exist?("/etc/apt/sources.list.d/sergey-dryabzhinsky-ubuntu-php#{version_without_dot}-bionic.list") }
end

execute "add repository sergey-dryabzhinsky/php7-modules" do
  command "add-apt-repository ppa:sergey-dryabzhinsky/php7-modules"
  not_if { File.exist?("/etc/apt/sources.list.d/sergey-dryabzhinsky-ubuntu-php7-modules-bionic.list") }
end

execute "add repository sergey-dryabzhinsky/backports" do
  command "add-apt-repository ppa:sergey-dryabzhinsky/backports"
  not_if { File.exist?("/etc/apt/sources.list.d/sergey-dryabzhinsky-ubuntu-backports-bionic.list") }
end

execute "add repository sergey-dryabzhinsky/packages" do
  command "add-apt-repository ppa:sergey-dryabzhinsky/packages"
  not_if { File.exist?("/etc/apt/sources.list.d/sergey-dryabzhinsky-ubuntu-packages-bionic.list") }
end

execute "apt-update" do
  command "apt update"
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
                "php#{version}-intl", "php#{version}-mbstring", "php#{version_without_dot}p-mod-mysql",
                "php#{version}-pgsql", "php#{version}-pspell", "php#{version}-snmp",
                "php#{version}-soap", "php#{version}-sqlite3", "php#{version}-tidy",
                "php#{version}-xml", "php#{version}-xmlrpc", "php#{version}-xsl",
                "php#{version}-zip"
               ]
end

extra_extensions = (fetch_env_var(node, "EY_PHP_EXTRA_EXTENSIONS") || '')
                     .split(',').map(&:strip).select { |x| !x.empty? }
if extra_extensions.length > 0
  package "extra PHP #{version} extensions" do
    action :upgrade
    package_name extra_extensions.map { |x| "php#{version}-#{x}" }
  end
end
