#### Scripted Gentoo installation with systemd on a LUKs encrypted ext4 filesystem for systems eith a NVMe SSD, x86-64 Intel CPU, Nvidia GPU and UEFI

1. Boot into BIOS and disable Secure Boot in you target computers UEFI (if there is an existing Windows installation that will be retained using BitLocker save recovery keys prior to this)
2. Boot into a live Gentoo environment https://wiki.gentoo.org/wiki/Handbook:AMD64/Installation/Media or https://wiki.gentoo.org/wiki/LiveUSB
3. Configure networking in the live environment (NetworkManager is present on the LiveGUI Usb Image) 
4. Pull this repository
5. Set enviornment variables based on example.env
6. Run: init_gentoo.sh
7. Boot into BIOS and clear Secure Boot Keys
9. Boot into live Gentoo environment
10. Run: fix_secureboot.sh
11. Boot into BIOS and enable Secure Boot
