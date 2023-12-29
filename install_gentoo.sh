#!/bin/bash
# Assumes called by init_gentoo.sh

set -u

export EFI_PARTITION ROOT_PARTITION
source /etc/profile
mkdir /efi
mount $EFI_PARTITION /efi

echo "Configuring and installing the system..."

mkdir --parents /etc/portage/repos.conf
cp /usr/share/portage/config/repos.conf /etc/portage/repos.conf/gentoo.conf

emerge-webrsync

# Hardcoding for NVIDIA GPU
cp /etc/portage/make.conf /etc/portage/make.conf.orig
patch -p0 <<EOF
--- /etc/portage/make.conf.orig 2023-12-12 13:34:45.515968935 -0500
+++ /etc/portage/make.conf      2023-12-12 15:14:01.205562418 -0500
@@ -2,7 +2,7 @@
 # built this stage.
 # Please consult /usr/share/portage/config/make.conf.example for a more
 # detailed example.
-COMMON_FLAGS="-O2 -pipe"
+COMMON_FLAGS="-march=native -O2 -pipe"
 CFLAGS="\${COMMON_FLAGS}"
 CXXFLAGS="\${COMMON_FLAGS}"
 FCFLAGS="\${COMMON_FLAGS}"
@@ -13,3 +13,8 @@
 # This sets the language of build output to English.
 # Please keep this setting intact when reporting bugs.
 LC_MESSAGES=C.utf8
+
+MAKEOPTS="-j4 -l4"
+USE="\${USE} networkmanager dist-kernel dbus"
+VIDEO_CARDS="intel nvidia"
+ACCEPT_LICENSE="-* @FREE @BINARY-REDISTRIBUTABLE Microsoft-vscode google-chrome"
EOF
emerge --ask app-portage/mirrorselect
mirrorselect -i -o >> /etc/portage/make.conf # https://mirror.csclub.uwaterloo.ca/gentoo-distfiles

echo 'sys-apps/systemd cryptsetup' > /etc/portage/package.use/systemd

emerge --ask app-portage/cpuid2cpuflags
echo "*/* $(cpuid2cpuflags)" > /etc/portage/package.use/00cpu-flags

eselect profile set 8 # Hardcoding default/linux/amd64/17.1/desktop/gnome/systemd/merged-usr (run `eselect profile list` to see the options)

emerge --ask --verbose --update --deep --newuse @world

cp /etc/localtime /etc/localtime.orig
ln -sf /usr/share/zoneinfo/America/Toronto /etc/localtime # Hardcoding

eselect locale set 4 # Hardcoding en_US (run `eselect locale list` to see the options)
env-update && source /etc/profile

echo "Installing the kernel..."

emerge --ask sys-kernel/linux-firmware sys-firmware/intel-microcode # Hardcoding For Intel CPU https://wiki.gentoo.org/wiki/Microcode#Microcode_firmware_blobs
emerge --ask sys-kernel/installkernel-gentoo
emerge --ask sys-kernel/gentoo-kernel

echo "Setting up system boot..."

fallocate -l 12GiB /swapfile
chmod 600 /swapfile
mkswap /swapfile

# https://forum.endeavouros.com/t/encrypting-root-with-dracut-grub-systemd-cryptsetup-generator/40418/13
# https://forums.gentoo.org/viewtopic-t-1062058-start-0.html
# https://superuser.com/questions/919590/dm-crypt-with-luks-etc-crypttab-using-either-keyfile-or-passphrase
ROOT_PARTITION_UUID=$(source <(blkid | grep ^$ROOT_PARTITION: | awk -F': ' '{ print $2 }') && echo $UUID)
echo "root	UUID=$ROOT_PARTITION_UUID	/crypt_key.luks	ext4	luks,discard" > /etc/crypttab # Hardcoding for NVMe TRIM https://man7.org/linux/man-pages/man5/crypttab.5.html#:~:text=discard

cp /etc/fstab /etc/fstab.orig
EFI_PARTITION_UUID=$(source <(blkid | grep ^$EFI_PARTITION: | awk -F': ' '{ print $2 }') && echo $UUID)
DECRYPTED_ROOT_PARITITON_UUID=$(source <(blkid | grep ^/dev/mapper/root: | awk -F': ' '{ print $2 }') && echo $UUID)
echo "UUID=$EFI_PARTITION_UUID	/efi	vfat	noauto,noatime	0 1" >> /etc/fstab
echo "UUID=$DECRYPTED_ROOT_PARITITON_UUID	/	ext4	defaults	0 1" >> /etc/fstab
echo "/swapfile	none	swap	sw	0 0" >> /etc/fstab

emerge --ask sys-kernel/dracut
cp /etc/dracut.conf /etc/dracut.conf.orig
echo 'add_dracutmodules+=" crypt dm rootfs-block "' >> /etc/dracut.conf
echo 'install_items+=" /etc/crypttab /crypt_key.luks "' >> /etc/dracut.conf
dracut --force --kver $(eselect kernel show | grep '/usr/src/linux-' | awk -F '/usr/src/linux-' '{ print $2 }')

echo 'GRUB_PLATFORMS="efi-64"' >> /etc/portage/make.conf
echo "sys-boot/grub:2 device-mapper" > /etc/portage/package.use/grub2
emerge --ask sys-boot/grub
cp /etc/default/grub /etc/default/grub.orig
patch -p0 <<EOF
--- /etc/default/grub.orig      2023-12-13 10:34:21.036455527 -0500
+++ /etc/default/grub   2023-12-13 10:37:14.466443672 -0500
@@ -74,3 +74,5 @@
 # This is useful, for example, to allow users who can't see the screen
 # to know when they can make a choice on the menu.
 #GRUB_INIT_TUNE="60 800 1"
+
+GRUB_ENABLE_CRYPTODISK=y
EOF
grub-install --target=x86_64-efi --efi-directory=/efi
grub-mkconfig -o /boot/grub/grub.cfg

echo 'sys-kernel/installkernel-gentoo dracut grub' > /etc/portage/package.use/installkernel-gentoo

wget https://dl.fedoraproject.org/pub/fedora/linux/releases/39/Everything/x86_64/os/Packages/s/shim-x64-15.6-2.x86_64.rpm # get signed shim (the shim in portage isn't signed)
rpmunpack shim-x64-15.6-2.x86_64.rpm
cp /shim-x64-15.6-2.x86_64/boot/efi/EFI/fedora/shimx64.efi /efi/EFI/gentoo/BOOTX64.EFI
cp /shim-x64-15.6-2.x86_64/boot/efi/EFI/fedora/mmx64.efi /efi/EFI/gentoo/
emerge --ask sys-boot/efibootmgr
efibootmgr --unicode --disk /dev/nvme0n1 --part 1 --create --label "gentoo shim" --loader /EFI/gentoo/BOOTX64.EFI

echo "Configuring the system..."

systemd-machine-id-setup
systemd-firstboot --prompt
systemctl preset-all --preset-mode=enable-only

passwd

source install_gentoo_extra.sh
source clean_gentoo.sh
