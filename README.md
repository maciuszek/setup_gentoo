#### Gentoo Linux Setup 

Scripts to provide a Gentoo installation with systemd on a LUKs encrypted ext4 filesystem
Hardware requirements: UEFI, NVMe SSD, x86-64 Intel CPU and Nvidia GPU

1. Boot into UEFI and disable Secure Boot (if there is an existing BitLocker encrypted Windows installation that will be retained save recovery keys prior to this)
2. Boot into a live Gentoo environment https://wiki.gentoo.org/wiki/Handbook:AMD64/Installation/Media or https://wiki.gentoo.org/wiki/LiveUSB
3. Configure networking in the live Gentoo environment (NetworkManager is present on the LiveGUI Usb Image) 
4. Pull this repository
5. Set STAGE_TARBALL, EFI_PARTITION and ROOT_PARTITION enviornment variables based on example.env
6. Run: init_gentoo.sh
7. Reboot into UEFI and clear Secure Boot Keys
9. Boot into a live Gentoo environment
10. Run: env ROOT_PARTITION='PATH_TO_GENTOO_INSTALLATION_BLOCK_DEVICE' fix_secureboot.sh
11. Reboot into BIOS and enable Secure Boot
12. Boot into the gentoo installation and login as root
13. Run: bash /post_install.sh