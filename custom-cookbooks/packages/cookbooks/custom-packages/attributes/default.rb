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
