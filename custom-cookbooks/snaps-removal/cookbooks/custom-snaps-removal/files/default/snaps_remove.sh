if systemctl is-active --quiet snapd.service snapd.socket; then
    snapd_was_active=yes
    echo
    echo "Stoping snapd..."
    echo
    (
        set -x
        systemctl stop snapd.socket snapd.service
    )
else
    echo "Skipping stopping snapd as systemctl reports it's inactive."
fi
echo
echo "Unmounting all snaps..."
echo
(
    set -x
    umount -l /var/lib/snapd/snaps/*.snap
)
echo
echo "Removing all support files and state..."
echo
(
    set -x
    rm -rvf /var/lib/snapd/*
)
echo
echo "Removing generated systemd units..."
echo
(
    set -x
    rm -vf /etc/systemd/system/snap-*.mount
    rm -vf /etc/systemd/system/snap-*.service
    rm -vf /etc/systemd/system/multi-user.target.wants/snap-*.mount
)
echo
echo "Removing generated executable wrappers..."
echo
(
    set -x
    rm -vrf /snap/*
)
if [ "$snapd_was_active" = "yes" ]; then
    echo
    echo "Starting snapd"
    (
        set -x
        systemctl start snapd.socket
    )
fi
