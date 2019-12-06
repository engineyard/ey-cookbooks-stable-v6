bash "make-swap-xvdc" do
  code <<-EOH
    exec > /var/log/make-swap-xvdc.log 2>&1  
    set -x
    parted -s -a optimal /dev/xvdc mklabel msdos
    echo "> $?"
    parted -s -a optimal -- /dev/xvdc unit compact mkpart primary linux-swap "1" "-1"
    echo "> $?"
    while [[ ! -b /dev/xvdc1 ]]; do
      echo "Waiting for 1 second"
      sleep 1
    done
    mkswap /dev/xvdc1
    echo "> $?"
    swapon /dev/xvdc1
    echo "> $?"
    echo "/dev/xvdc1 swap swap sw 0 0" >> /etc/fstab
  EOH
  only_if { File.exists?("/dev/xvdc") && !system("grep -q '/dev/xvdc1' /etc/fstab") && (`blkid /dev/xvdc1 -o value -s TYPE` !~ /^swap/) }
end
