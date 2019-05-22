# Report to Cloud dashboard
ey_cloud_report "processing php" do
  message "processing php - install"
end

version = node["php"]["minor_version"]

execute "add repository" do
  command "add-apt-repository ppa:ondrej/php"
  not_if { File.exist?("/etc/apt/sources.list.d/ondrej-ubuntu-php-bionic.list") }
end

package "php#{version}"
package "php#{version}-mbstring"
