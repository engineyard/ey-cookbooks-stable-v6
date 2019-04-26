# Specify packages and version numbers to be installed here
#
# Search for packages on instances using: apt-cache search <package name>
#
# Examples below:
default['packages'].tap do |packages|
  packages['install'] = [
    {'name' => "sphinxsearch", 'version' => "2.2.11-2"},
    {'name' => "wkhtmltopdf"}
  ]
end

# To install a package from a different repository, you need to add the key and source to apt.
# For example, to install yarn from their own repository, their instructions tell you to run the following commands on the command line
# curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | sudo apt-key add -
# echo "deb https://dl.yarnpkg.com/debian/ stable main" | sudo tee /etc/apt/sources.list.d/yarn.list
#
# Instead of running those commands, you can use the recipe to add the key and source and to install the package.
# 1) add the URL of the gpg key to 'keys'
# 2) add the name and content of the apt source to 'apt_sources'
# 3) add the package to 'install'

=begin
default['packages'].tap do |packages|
  packages['keys'] = [
    {"url" => "https://dl.yarnpkg.com/debian/pubkey.gpg"}
  ]

  packages['apt_sources'] = [
    {"name" => "yarn", "content" => "deb https://dl.yarnpkg.com/debian/ stable main"}
  ]

  packages['install'] = [
    {'name' => 'yarn'}
  ]
end
=end
