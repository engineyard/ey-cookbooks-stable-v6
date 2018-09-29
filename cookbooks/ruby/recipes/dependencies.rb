if node[:ruby][:version] =~ /^2\.3/
  package "libssl1.0-dev" do
    action :install
  end
else # ruby 2.4
  package "libssl-dev" do
    action :install
  end
end

package "bison"
package "zlib1g-dev"
package "libyaml-dev"
package "libgdbm-dev"
package "libreadline-dev"
package "libncurses5-dev"
package "libffi-dev"
