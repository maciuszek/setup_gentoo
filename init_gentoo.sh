#!/bin/bash

# Basic Gentoo Installation With Systemd On A LUKs Encrypted EXT4 Filesystem For Systems With An NVMe SSD, AMD64 Intel CPU, NVIDIA GPU and UEFI

# https://wiki.gentoo.org/wiki/Handbook:AMD64
# https://wiki.gentoo.org/wiki/Full_Disk_Encryption_From_Scratch
# https://wiki.gentoo.org/wiki/Handbook:AMD64/Installation/Disks
# https://wiki.gentoo.org/wiki/Ext4
# https://wiki.gentoo.org/wiki/Swap#Swap_files
# https://wiki.gentoo.org/wiki//etc/fstab
# https://wiki.gentoo.org/wiki/Handbook:AMD64/Installation/Stage
# https://wiki.gentoo.org/wiki/Handbook:AMD64/Installation/Base
# https://wiki.gentoo.org/wiki/License_groups
# https://wiki.gentoo.org/wiki//etc/portage/make.conf#VIDEO_CARDS
# https://wiki.gentoo.org/wiki/NVIDIA/nvidia-drivers
# https://wiki.gentoo.org/wiki/Systemd
# https://wiki.gentoo.org/wiki/GNOME/Guide
# https://wiki.gentoo.org/wiki/NetworkManager
# https://wiki.gentoo.org/wiki/USE_flag
# https://www.gentoo.org/support/use-flags/
# https://wiki.gentoo.org/wiki/Handbook:AMD64/Installation/Kernel
# https://wiki.gentoo.org/wiki/Microcode
# https://wiki.gentoo.org/wiki/Intel_microcode
# https://wiki.gentoo.org/wiki/Handbook:AMD64/Installation/System
# https://wiki.gentoo.org/wiki/Handbook:AMD64/Installation/Tools
# https://wiki.gentoo.org/wiki/Handbook:AMD64/Installation/Bootloader
# https://wiki.gentoo.org/wiki/Dracut
# https://wiki.gentoo.org/wiki/SSD#Discard_.28trim.29_support
# https://wiki.gentoo.org/wiki/GRUB
# https://wiki.gentoo.org/wiki/GRUB/Advanced_storage
# https://wiki.gentoo.org/wiki/Rootfs_encryption
# https://wiki.gentoo.org/wiki/Dm-crypt
# https://wiki.gentoo.org/wiki/Dm-crypt_full_disk_encryption
# https://wiki.archlinux.org/title/dm-crypt/System_configuration
# https://wiki.archlinux.org/title/dm-crypt/Encrypting_an_entire_system
# https://wiki.gentoo.org/wiki/Handbook:AMD64/Installation/Finalizing
# https://wiki.gentoo.org/wiki/Secure_Boot
# https://wiki.gentoo.org/wiki/User:Sakaki/Sakaki%27s_EFI_Install_Guide/Configuring_Secure_Boot
# https://wiki.gentoo.org/wiki/Project:Distribution_Kernel
# https://wiki.gentoo.org/wiki/Shim

# Note: This script assumes a GPT partition table with an EFI and 1 unformatted Linux filsystem parition precreated (use parted/gparted to resize and create)

set -u

STAGE_TARBALL=$STAGE_TARBALL # Set from https://www.gentoo.org/downloads/ (must be stage3-amd64-desktop-systemd-mergedusr-* tarball)

EFI_PARTITION=$EFI_PARTITION
ROOT_PARTITION=$ROOT_PARTITION

echo "Encrypting and formating $ROOT_PARTITION..."

cryptsetup luksFormat --type luks1 --key-size 512 $ROOT_PARTITION
dd bs=8388608 count=1 if=/dev/urandom of=crypt_key.luks
cryptsetup luksAddKey $ROOT_PARTITION crypt_key.luks
sudo cryptsetup --key-file crypt_key.luks luksOpen $ROOT_PARTITION root
mkfs.ext4 /dev/mapper/root
sudo mkdir /mnt/gentoo
sudo mount /dev/mapper/root /mnt/gentoo
sudo cp crypt_key.luks /mnt/gentoo/

echo "Downloading and extracting the base system..."

(cd /mnt/gentoo
sudo wget $STAGE_TARBALL
sudo tar xpvf stage3-*.tar.xz --xattrs-include='*.*' --numeric-owner)

echo "Rooting into the installation..."

sudo cp --dereference /etc/resolv.conf /mnt/gentoo/etc/
sudo cp *_gentoo*.sh /mnt/gentoo/
sudo arch-chroot /mnt/gentoo/ /usr/bin/env \
    EFI_PARTITION=$EFI_PARTITION \
    ROOT_PARTITION=$ROOT_PARTITION \
    /bin/bash install_gentoo.sh
