#### Gentoo Linux Setup 

Scripts to provide a Gentoo installation with systemd on a LUKs encrypted ext4 filesystem
Hardware requirements: UEFI, NVMe SSD, x86-64 Intel CPU and Nvidia GPU

1. Boot into UEFI and disable Secure Boot
2. Boot into a live Gentoo environment https://wiki.gentoo.org/wiki/Handbook:AMD64/Installation/Media or https://wiki.gentoo.org/wiki/LiveUSB
3. Configure networking in the live Gentoo environment (NetworkManager is present on the LiveGUI Usb Image) 
4. Clone this repository and change working directory to the repostiory root 
5. Set STAGE_TARBALL, EFI_PARTITION and ROOT_PARTITION enviornment variables based on example.env
6. Run: ./init_gentoo.sh
7. Reboot into UEFI and clear Secure Boot Keys (if there are any existing BitLocker encrypted Windows installation save the recovery keys)
8. Boot into the Gentoo installation and login as root
9. Run: bash /install_secureboot_keys.sh
10. Setup networking (ifconfig, wpa_supplicant, wpa_passphrase and dhcpcd are avaible)
11. Run: bash /post_install.sh
12. Reboot into BIOS and enable Secure Boot
