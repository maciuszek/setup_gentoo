#!/bin/bash
# Assumes called by install_gentoo.sh

set -u

echo "Installing user software..."

emerge --ask net-misc/dhcpcd \
    sys-apps/mlocate \
    app-shells/bash-completion \
    sys-fs/e2fsprogs \
    sys-fs/dosfstools \
    sys-block/io-scheduler-udev-rules \
    net-wireless/iw net-wireless/wpa_supplicant

echo "media-libs/libsndfile minimal" > /etc/portage/package.use/libsndfile # Fix circular dependency
emerge --ask gnome-base/gnome

env-update && source /etc/profile

echo "Configuring the system and basic user..."

systemctl enable dhcpcd
systemctl enable sshd
systemctl enable systemd-timesyncd.service
systemctl enable gdm.service

read -p "Enter username for basic user: " USERNAME
useradd -m -G users,wheel,audio -s /bin/bash $USERNAME
passwd $USERNAME
