#!/bin/bash
# Original file name: "prepare_release.sh"
# Created: 2021.06.03
# Last modified: 2021.06.04
# License: BSD-3-clause
# Written by: Astaf'ev Sergey <seryymail@mail.ru>
# This is a part of RBOINC R package.
# Copyright (c) 2021 Karelian Research Centre of the RAS:
# Institute of Applied Mathematical Research
# All rights reserved

echo "Cleaning portage cache:"
eclean distfiles
eclean packages
echo "Cleaning logs:"
truncate -s 0 /var/log/emerge.log
truncate -s 0 /var/log/emerge-fetch.log
rm -r /var/log/portage/*
echo "Defragment file system:"
btrfs filesystem defragment -r /
echo "Rebalance BTRFS:"
btrfs balance start /
