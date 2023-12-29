#!/bin/bash
# Assumes called by install_gentoo.sh

set -u

echo "Install drivers..."

# Todo remove prime-run
emerge --ask nvidia-drivers \
    x11-misc/prime-run

echo "Installing user software..."

# Todo remove mesa
emerge --ask net-misc/dhcpcd \
    sys-apps/mlocate \
    app-shells/bash-completion \
    sys-fs/e2fsprogs \
    sys-fs/dosfstools \
    sys-block/io-scheduler-udev-rules \
    net-wireless/iw net-wireless/wpa_supplicant \
    net-misc/networkmanager \
    app-admin/sudo \
    media-libs/mesa \
    x11-apps/mesa-progs \
    x11-apps/xrandr \
    app-editors/vim \
    app-editors/vscode

# Todo remove switcheroo-control
echo "media-libs/libsndfile minimal" > /etc/portage/package.use/libsndfile # Fix circular dependency
emerge --ask gnome-base/gnome \
    gnome-extra/gnome-tweaks \
    sys-power/switcheroo-control \
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
