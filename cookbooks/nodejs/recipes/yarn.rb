execute "add key from yarn repository" do
  command "curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | sudo apt-key add -"
  not_if 'apt-key adv --list-public-key --with-fingerprint --with-colons | grep Yarn -q'
end

file "apt source yarn" do
  path "/etc/apt/sources.list.d/yarn.list"
  content "deb https://dl.yarnpkg.com/debian/ stable main"
  notifies :run, "execute[update-apt]", :immediately
end

package "yarn" do
  action :install
  options '--no-install-recommends'
end
