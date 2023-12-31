#!/bin/bash
# Assumes called by init_gentoo.sh

set -u

function install_base_system {
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
+USE="\${USE} networkmanager dist-kernel dbus bluetooth pulseaudio alsa"
+VIDEO_CARDS="intel nvidia"
+ACCEPT_LICENSE="-* @FREE @BINARY-REDISTRIBUTABLE Microsoft-vscode google-chrome"
EOF
    emerge --ask app-portage/mirrorselect
    mirrorselect -i -o >> /etc/portage/make.conf # https://mirror.csclub.uwaterloo.ca/gentoo-distfiles

    emerge --ask app-portage/cpuid2cpuflags
    echo "$(cpuid2cpuflags | sed 's/: /=\"/' | sed 's/$/\"/')" >> /etc/portage/make.conf

    echo 'sys-apps/systemd cryptsetup' > /etc/portage/package.use/systemd

    eselect profile set 8 # Hardcoding default/linux/amd64/17.1/desktop/gnome/systemd/merged-usr (run `eselect profile list` to see the options)

    emerge --ask --verbose --update --deep --newuse @world

    env-update && source /etc/profile
}

function install_kernel {
    emerge --ask sys-kernel/linux-firmware
    emerge --ask sys-firmware/intel-microcode # Hardcoding For Intel CPU https://wiki.gentoo.org/wiki/Microcode#Microcode_firmware_blobs
    emerge --ask sys-kernel/installkernel-gentoo
    emerge --ask sys-kernel/gentoo-kernel

    env-update && source /etc/profile
}

function create_crypttab {
    # https://forum.endeavouros.com/t/encrypting-root-with-dracut-grub-systemd-cryptsetup-generator/40418/13
    # https://forums.gentoo.org/viewtopic-t-1062058-start-0.html
    # https://superuser.com/questions/919590/dm-crypt-with-luks-etc-crypttab-using-either-keyfile-or-passphrase
    ROOT_PARTITION_UUID=$(source <(blkid | grep ^$ROOT_PARTITION: | awk -F': ' '{ print $2 }') && echo $UUID)
    echo "root	UUID=$ROOT_PARTITION_UUID	/crypt_key.luks	ext4	luks,discard" > /etc/crypttab # Hardcoding for NVMe TRIM https://man7.org/linux/man-pages/man5/crypttab.5.html#:~:text=discard
}

function install_initrd {
    emerge --ask sys-kernel/dracut
    cp /etc/dracut.conf /etc/dracut.conf.orig
    echo 'add_dracutmodules+=" crypt dm rootfs-block "' >> /etc/dracut.conf
    echo 'install_items+=" /etc/crypttab /crypt_key.luks "' >> /etc/dracut.conf
    dracut --force --kver $(eselect kernel show | grep '/usr/src/linux-' | awk -F '/usr/src/linux-' '{ print $2 }')

    env-update && source /etc/profile
}

function create_secureboot_keys {
    emerge --ask app-crypt/sbsigntools \
        app-crypt/efitools \
        dev-libs/openssl

    mkdir -p /efikeys
    chmod -v 700 /efikeys

    efi-readvar -v KEK -o old_KEK.esl
    efi-readvar -v db -o old_db.esl
    efi-readvar -v db -o old_db.esl
    efi-readvar -v dbx -o old_dbx.esl

    openssl req -new -x509 -newkey rsa:2048 -subj "/CN=maciuszek's platform key/" -keyout PK.key -out PK.crt -days 3650 -nodes -sha256
    openssl req -new -x509 -newkey rsa:2048 -subj "/CN=maciuszek's key-exchange-key/" -keyout KEK.key -out KEK.crt -days 3650 -nodes -sha256
    openssl req -new -x509 -newkey rsa:2048 -subj "/CN=maciuszek's kernel-signing key/" -keyout db.key -out db.crt -days 3650 -nodes -sha256

    chmod -v 400 *.key

    cert-to-efi-sig-list -g "$(uuidgen)" PK.crt PK.esl
    sign-efi-sig-list -k PK.key -c PK.crt PK PK.esl PK.auth

    cert-to-efi-sig-list -g "$(uuidgen)" KEK.crt KEK.esl
    sign-efi-sig-list -a -k PK.key -c PK.crt KEK KEK.esl KEK.auth

    cert-to-efi-sig-list -g "$(uuidgen)" db.crt db.esl
    sign-efi-sig-list -a -k KEK.key -c KEK.crt db db.esl db.auth

    sign-efi-sig-list -k KEK.key -c KEK.crt dbx old_dbx.esl old_dbx.auth

    openssl x509 -outform DER -in PK.crt -out PK.cer
    openssl x509 -outform DER -in KEK.crt -out KEK.cer
    openssl x509 -outform DER -in db.crt -out db.cer

    cat old_KEK.esl KEK.esl > compound_KEK.esl
    cat old_db.esl db.esl > compound_db.esl
    sign-efi-sig-list -k PK.key -c PK.crt KEK compound_KEK.esl compound_KEK.auth
    sign-efi-sig-list -k KEK.key -c KEK.crt db compound_db.esl compound_db.auth
}

function create_fstab {
    cp /etc/fstab /etc/fstab.orig
    EFI_PARTITION_UUID=$(source <(blkid | grep ^$EFI_PARTITION: | awk -F': ' '{ print $2 }') && echo $UUID)
    DECRYPTED_ROOT_PARITITON_UUID=$(source <(blkid | grep ^/dev/mapper/root: | awk -F': ' '{ print $2 }') && echo $UUID)
    echo "UUID=$EFI_PARTITION_UUID	/efi	vfat	noauto,noatime	0 1" >> /etc/fstab
    echo "UUID=$DECRYPTED_ROOT_PARITITON_UUID	/	ext4	defaults	0 1" >> /etc/fstab
}

function create_swap_file {
    fallocate -l 12GiB /swapfile
    chmod 600 /swapfile
    mkswap /swapfile
    echo "/swapfile	none	swap	sw	0 0" >> /etc/fstab
}

function install_bootloader {
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
    grub-install --efi-directory=/efi
    grub-mkconfig -o /boot/grub/grub.cfg
    grub-mkstandalone --disable-shim-lock --fonts=all -O x86_64-efi -o /efi/EFI/gentoo/grubx64.efi "/boot/grub/grub.cfg" -v
    sed -i 's/SecureBoot/SecureB00t/' /efi/EFI/gentoo/grubx64.efi # https://wejn.org/2021/09/fixing-grub-verification-requested-nobody-cares/

    emerge --ask sys-boot/efibootmgr
    #efibootmgr --bootnum 0000 --delete-bootnum
    #efibootmgr --create --label "gentoo" --loader /EFI/gentoo/grubx64.efi

    sbsign --key /efikeys/db.key --cert /efikeys/db.crt --output /efi/EFI/gentoo/grubx64.efi /efi/EFI/gentoo/grubx64.efi
    # confirm signature with `sbverify --cert /efikeys/db.crt /efi/EFI/gentoo/grubx64.efi`

    env-update && source /etc/profile
}

function install_extra_software {
    emerge --ask net-misc/dhcpcd \
            sys-apps/mlocate \
            app-shells/bash-completion \
            sys-fs/e2fsprogs \
            sys-fs/dosfstools \
            sys-block/io-scheduler-udev-rules \
            net-wireless/iw net-wireless/wpa_supplicant \
            app-portage/gentoolkit \
            app-admin/sudo \
            app-editors/nano
    
    systemctl enable dhcpcd
    systemctl enable sshd

    env-update && source /etc/profile
}

function configure_installation {
    eselect locale set 4 # Hardcoding en_US (run `eselect locale list` to see the options)

    cp /etc/localtime /etc/localtime.orig
    ln -sf /usr/share/zoneinfo/America/Toronto /etc/localtime # Hardcoding

    systemctl enable systemd-timesyncd.service

    # hostnamectl hostname tux

    systemd-machine-id-setup
    systemd-firstboot --prompt # Set keymap to 'us'. Set hostname to match Windows hostname 
    systemctl preset-all --preset-mode=enable-only

    passwd

    env-update && source /etc/profile
}

function clean_installation {
    emerge --depclean
    # rm /stage3-*.tar.*

    env-update && source /etc/profile
}

source /etc/profile

export EFI_PARTITION ROOT_PARTITION

mkdir /efi
mount $EFI_PARTITION /efi

install_base_system
install_kernel
create_crypttab
install_initrd
create_secureboot_keys
create_fstab
create_swap_file
install_bootloader
install_extra_software
configure_installation
clean_installation

# rm /install_gentoo.sh
