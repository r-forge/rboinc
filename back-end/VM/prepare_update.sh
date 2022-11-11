#!/bin/bash
# Original file name: "prepare_update.sh"
# Created: 2022.07.18
# Last modified: 2022.11.09
# License: BSD-3-clause
# Written by: Astaf'ev Sergey <seryymail@mail.ru>
# This is a part of RBOINC R package
# Copyright (c) 2022 Karelian Research Centre of
# the RAS: Institute of Applied Mathematical Researh
# All rights reserved

emerge-webrsync
#emerge --sync
emerge --verbose --update --deep --changed-use --newuse @world
emerge @preserved-rebuild
revdep-rebuild
./scripts/root/prepare_release.sh
./enter.sh x64 /root/scripts/update_packages.sh
./enter.sh x32 /root/scripts/update_packages.sh

