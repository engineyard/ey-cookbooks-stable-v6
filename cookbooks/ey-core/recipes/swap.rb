bash "make-swap-xvdc" do
  code <<-EOH
    parted -s -a optimal /dev/xvdc mklabel msdos
    parted -s -a optimal -- /dev/xvdc unit compact mkpart primary linux-swap "1" "-1"
    while [[ ! -b /dev/xvdc1 ]]; do
      sleep 1
    done
    mkswap /dev/xvdc1
    swapon /dev/xvdc1
    echo "/dev/xvdc1 swap swap sw 0 0" >> /etc/fstab
  EOH
  only_if { File.exists?("/dev/xvdc") && !system("grep -q '/dev/xvdc1' /etc/fstab") && (`blkid /dev/xvdc1 -o value -s TYPE` !~ /^swap/) }
end
