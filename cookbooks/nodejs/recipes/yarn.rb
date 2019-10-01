apt_repository 'yarn' do
  uri 'https://dl.yarnpkg.com/debian/'
  components ['main', 'stable']
  key 'https://dl.yarnpkg.com/debian/pubkey.gpg'
  action :add
end

package "yarn" do
  action :install
  options '--no-install-recommends --allow-downgrades'
end
