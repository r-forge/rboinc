#!/bin/bash
# Original file name: "prepare_release.sh"
# Created: 2021.06.03
# Last modified: 2022.01.11
# License: BSD-3-clause
# Written by: Astaf'ev Sergey <seryymail@mail.ru>
# This is a part of RBOINC R package.
# Copyright (c) 2021-2022 Karelian Research Centre of
# the RAS: Institute of Applied Mathematical Research
# All rights reserved

echo "Deleting packages:"
emerge --depclean --deep
echo "Cleaning portage cache:"
eclean distfiles
eclean packages
eselect news purge
echo "Cleaning logs:"
truncate -s 0 /var/log/emerge.log
truncate -s 0 /var/log/emerge-fetch.log
truncate -s 0 /var/log/lastlog
truncate -s 0 /var/log/wtmp
echo -e "\033[32mCleaning completed. Copy fs to new disk to reduce size.\033[0m"
