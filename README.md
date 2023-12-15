#### Scripted Gentoo installation with systemd on a LUKs encrypted ext4 filesystem for systems eith a NVMe SSD, x86-64 Intel CPU, Nvidia GPU and UEFI

1. Disable Secure Boot in you target computers UEFI (This can be re-enabled later)
2. Boot into a live Gentoo environment https://wiki.gentoo.org/wiki/Handbook:AMD64/Installation/Media
3. Configure networking
4. Pull this repository
5. Review all the shell scripts
6. Set enviornment variables based on example.env
7. Run: init_gentoo.sh
