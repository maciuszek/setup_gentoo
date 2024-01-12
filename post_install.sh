#!/bin/bash

function setup_nvidia {
    emerge --ask x11-drivers/nvidia-drivers \
        x11-misc/prime-run \
        sys-apps/lshw \
        x11-apps/xrandr \
        x11-apps/mesa-progs

    modprobe -r nouveau
    modprobe nvidia
    nvidia-xconfig --prime

    env-update && source /etc/profile
}

function setup_sound {
    emerge --ask sys-firmware/sof-firmware \
        media-sound/alsa-utils \
	    media-sound/pulseaudio \
        media-plugins/alsa-plugins \
        media-sound/pavucontrol

    systemctl --global enable pulseaudio.service pulseaudio.socket

    env-update && source /etc/profile
}

function setup_bluetooth {
    emerge --ask net-wireless/bluez

    systemctl enable bluetooth.service

    env-update && source /etc/profile
}

function install_gnome {
    echo "media-libs/libsndfile minimal" > /etc/portage/package.use/libsndfile # Fix circular dependency
    emerge --ask gnome-base/gnome \
        gnome-extra/gnome-tweaks \
        net-misc/networkmanager

    systemctl enable gdm.service
    systemctl enable NetworkManager.service

    env-update && source /etc/profile
}

function install_extra_software {
    emerge --ask app-editors/vim \
        app-editors/vscode \
        dev-vcs/gitg \
        www-client/google-chrome \
        media-sound/gnome-sound-recorder

    echo 'net-firewall/nftables json python xtables' > /etc/portage/package.use/nftables
    emerge --ask net-firewall/firewalld
    systemctl enable firewalld.service

    emerge --ask app-antivirus/clamav
    echo 'OnAccessPrevention yes' >> /etc/clamav/clamd.conf
    echo 'OnAccessIncludePath /home/maciuszek/Download' >> /etc/clamav/clamd.conf
    echo 'OnAccessExcludeUname clamav' >> /etc/clamav/clamd.conf

    systemctl enable clamav-freshclam.service
    systemctl enable clamd.service
    systemctl enable clamav-daemon.service
    # todo determine how to start clamonacc
    
    env-update && source /etc/profile
}

function configure_localtime {
    timedatectl set-local-rtc 1
}

function setup_user {
    read -p "Enter username for basic user: " USERNAME
    useradd -m -G users,wheel,audio,video -s /bin/bash $USERNAME
    passwd $USERNAME
}

function clean_post_installation {
    emerge --depclean

    env-update && source /etc/profile
}

setup_nvidia
setup_sound
setup_bluetooth
install_gnome
install_extra_software
configure_localtime
setup_user
clean_post_installation

# rm /post_install.sh
