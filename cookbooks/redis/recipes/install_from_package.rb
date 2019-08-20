package "redis" do
  action :install
  options "-o Dpkg::Options::=\"--force-confdef\" -o Dpkg::Options::=\"--force-confold\""
end
