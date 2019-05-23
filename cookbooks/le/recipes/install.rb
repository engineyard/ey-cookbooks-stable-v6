cookbook_file "/tmp/logentries.key" do
  source "logentries.key"
end

execute "add logentries key" do
  command "apt-key add /tmp/logentries.key"
  not_if "apt-key adv --list-public-key --with-fingerprint --with-colons | grep -q A5270289C43C79AD"
end

file "/etc/apt/sources.list.d/logentries.list" do
  content "deb http://rep.logentries.com/ bionic main"
  notifies :run, "execute[update-apt]", :immediately
end

package "logentries"
package "logentries-daemon"
