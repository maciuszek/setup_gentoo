#!/bin/bash
# Assumes called by install_gentoo.sh

echo "Cleaning up the installation..."

emerge --depclean

# Leave installation files
