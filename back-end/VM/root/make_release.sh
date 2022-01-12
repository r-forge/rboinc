#!/bin/bash
# Original file name: "make_release.sh"
# Created: 2021.07.12
# Last modified: 2022.01.11
# License: BSD-3-clause
# Written by: Astaf'ev Sergey <seryymail@mail.ru>
# This is a part of RBOINC R package.
# Copyright (c) 2021-2022 Karelian Research Centre of
# the RAS: Institute of Applied Mathematical Research
# All rights reserved

echo -e '\033[31m********************************************************************'
echo -e '\033[31m*************************\033[33m !!! WARNING !!! \033[31m**************************'
echo -e '\033[31m*\033[33m This script is intended for extreme reduction in the size of     \033[31m*'
echo -e '\033[31m*\033[33m virtual machine before downloading to the BOINC server. It       \033[31m*'
echo -e '\033[31m*\033[33m irreversibly damages the image of a virtual machine making it    \033[31m*'
echo -e '\033[31m*\033[33m unsuitable for normal use. Before answering yes, make sure that: \033[31m*'
echo -e '\033[31m*\033[33m  1. You have completed the maintenance of the virtual machine.   \033[31m*'
echo -e '\033[31m*\033[33m  2. You have a copy of the current state of the virtual machine. \033[31m*'
echo -e '\033[31m********************************************************************\033[0m'
read -r -p 'Are you sure you want to continue? (y\n): ' response
case "$response" in [Yy][Ee][Ss]|[Yy])
    echo "Deleting packages..."
    emerge --deselect sys-boot/grub
    emerge --deselect sys-kernel/gentoo-sources
    emerge --deselect sys-fs/btrfs-progs
    emerge --depclean --deep
    echo "Deleting kernel..."
    rm -r /usr/src/*
    echo "Cleaning portage cache..."
    eclean distfiles
    eclean packages
    echo "Deleting packages..."
    emerge --deselect app-portage/gentoolkit
    emerge --depclean --deep
    echo "Installing run script..."
    rm /home/boinc/boinc_app.sh
    cp boinc_app.sh /home/boinc/
    chmod +x /home/boinc/boinc_app.sh
    chmod +s `which reboot`
    chmod +s `which shutdown`
    echo "Cleaning logs..."
    truncate -s 0 /var/log/emerge.log
    truncate -s 0 /var/log/emerge-fetch.log
    truncate -s 0 /root/.bash_history
    truncate -s 0 /home/boinc/.bash_history
    rm -r /var/log/portage/*
    echo "Deleting tmp..."
    rm /grub2-sh-*
    rm -r /var/tmp/*
    rm -r /tmp/*
    echo "Deleting mans..."
    rm -r /usr/share/man/*
    echo "Deleting repository..."
    rm -r /var/db/repos/*
    rm -r /var/db/pkg/*
    echo "Deleting caches..."
    rm -r /var/cache
    echo "Deleting unnecessary files..."
    rm -r /usr/share/doc/*
    echo -e "\033[32mCleaning completed. Copy fs to new disk to reduce size.\033[0m"
    ;;
    *)
    echo "Exiting."
    ;;
esac
