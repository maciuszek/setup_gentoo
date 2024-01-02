#!/bin/bash

set -u

ROOT_PARTITION=$ROOT_PARTITION

sudo cryptsetup luksOpen $ROOT_PARTITION root
sudo mount /dev/mapper/root /mnt/gentoo

sudo cp install_secureboot_keys.sh /mnt/gentoo/
sudo arch-chroot /mnt/gentoo/ \
    /bin/bash install_secureboot_keys.sh /
