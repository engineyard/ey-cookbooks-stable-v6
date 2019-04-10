# Monitor sshd
cookbook_file "/etc/ssh/sshd_config" do
  owner "root"
  group "root"
  backup 0
  mode 0600
  source "sshd_config"
  not_if { File.exists?("/etc/ssh/keep.sshd_config") }
end

# OpenSSH and Logjam
bash 'Enforce strong Moduli' do
  code "awk '$5 >= 3071' /etc/ssh/moduli > /etc/ssh/moduli.strong && cp /etc/ssh/moduli.strong /etc/ssh/moduli"
  not_if { File.exists?("/etc/ssh/moduli.strong") }
end

service "sshd" do
  action :restart
end
