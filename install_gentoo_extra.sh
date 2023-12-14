#!/bin/bash
# Assumes called by install_gentoo.sh

emerge --ask net-misc/dhcpcd \
    sys-apps/mlocate \
    app-shells/bash-completion \
    sys-fs/e2fsprogs \
    sys-fs/dosfstools \
    sys-block/io-scheduler-udev-rules \
    net-wireless/iw net-wireless/wpa_supplicant

systemctl enable dhcpcd
systemctl enable sshd
systemctl enable systemd-timesyncd.service

read -p "Enter username for basic user: " USERNAME
useradd -m -G users,wheel,audio -s /bin/bash $USERNAME
passwd $USERNAME

# TODO: https://wiki.gentoo.org/wiki/GNOME/Guide
