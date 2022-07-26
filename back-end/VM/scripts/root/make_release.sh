#!/bin/bash
# Original file name: "make_release.sh"
# Created: 2021.07.12
# Last modified: 2022.07.21
# License: BSD-3-clause
# Written by: Astaf'ev Sergey <seryymail@mail.ru>
# This is a part of RBOINC R package.
# Copyright (c) 2021-2022 Karelian Research Centre of
# the RAS: Institute of Applied Mathematical Research
# All rights reserved

if [ "${1}" != "I_am_running_from_script." ] && [ "${2}" != "Yes,_I_am_exactly_running_from_script!!!" ] && [ $# != 2 ];
then
    echo -e '\033[31mThis script is not for manual execution!\033[0m'
    exit 1
fi

echo "Deleting packages..."
emerge --deselect sys-kernel/gentoo-sources
emerge --depclean --deep
echo "Deleting kernel..."
rm -r /usr/src/*
echo "Cleaning portage cache..."
eclean distfiles
eclean packages
eselect news purge
echo "Deleting packages..."
emerge --deselect app-portage/gentoolkit
emerge --depclean --deep
echo "Installing run script..."
rm /home/boinc/boinc_app.sh
cp /root/scripts/boinc_app.sh /home/boinc/
chmod +x /home/boinc/boinc_app.sh
chmod +s `which reboot`
chmod +s `which shutdown`
echo "Cleaning logs..."
truncate -s 0 /var/log/emerge.log
truncate -s 0 /var/log/emerge-fetch.log
truncate -s 0 /var/log/dmesg
truncate -s 0 /var/log/lastlog
truncate -s 0 /var/log/wtmp
truncate -s 0 /root/.bash_history
truncate -s 0 /home/boinc/.bash_history
rm -r /var/log/portage/*
echo "Deleting tmp..."
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
