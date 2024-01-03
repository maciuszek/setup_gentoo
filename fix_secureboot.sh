#!/bin/bash

# This scripts is intended to be executed after init_gentoo.sh has completed and secure boot keys in uefi have been cleared 

set -u

ROOT_PARTITION=$ROOT_PARTITION

sudo cryptsetup luksOpen $ROOT_PARTITION root
sudo mount /dev/mapper/root /mnt/gentoo

sudo cp install_secureboot_keys.sh /mnt/gentoo/
sudo arch-chroot /mnt/gentoo/ \
    /bin/bash install_secureboot_keys.sh /
