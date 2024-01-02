#### Scripted Gentoo installation with systemd on a LUKs encrypted ext4 filesystem for systems eith a NVMe SSD, x86-64 Intel CPU, Nvidia GPU and UEFI

# TODO: update hardcoded paths, kernels, and disks

1. Disable Secure Boot in you target computers UEFI (This can be re-enabled later)
2. Boot into a live Gentoo environment https://wiki.gentoo.org/wiki/Handbook:AMD64/Installation/Media
3. Configure networking
4. Pull this repository
5. Review all the shell scripts
6. Set enviornment variables based on example.env
7. Run: init_gentoo.sh
8. Reboot into BIOS and Clear Secure Boot Keys
9. Reboot into live Gentoo environment unlock, mount and root into installation. Run: /install_secure_boot_keys.sh
10. Enable Secure Boot
