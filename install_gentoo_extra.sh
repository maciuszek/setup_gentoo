#!/bin/bash
# Assumes called by install_gentoo.sh

set -u

echo "Install drivers..."

emerge --ask nvidia-drivers

echo "Installing user software..."

emerge --ask net-misc/dhcpcd \
    sys-apps/mlocate \
    app-shells/bash-completion \
    sys-fs/e2fsprogs \
    sys-fs/dosfstools \
    sys-block/io-scheduler-udev-rules \
    net-wireless/iw net-wireless/wpa_supplicant \
    app-admin/sudo \
    x11-apps/xrandr \
    x11-apps/mesa-progs \
    app-editors/vim \
    app-editors/vscode

emerge --ask www-client/google-chrome

echo "media-libs/libsndfile minimal" > /etc/portage/package.use/libsndfile # Fix circular dependency
emerge --ask gnome-base/gnome \
    gnome-extra/gnome-tweaks \
    net-misc/networkmanager \
    dev-vcs/gitg

env-update && source /etc/profile

echo "Configuring the system and basic user..."

systemctl enable dhcpcd
systemctl enable sshd
systemctl enable systemd-timesyncd.service
systemctl enable gdm.service
systemctl enable NetworkManager.service

read -p "Enter username for basic user: " USERNAME
useradd -m -G users,wheel,audio -s /bin/bash $USERNAME
passwd $USERNAME
