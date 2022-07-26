#!/bin/bash
# Original file name: "update_packages.sh"
# Created: 2022.07.22
# Last modified: 2022.07.22
# License: BSD-3-clause
# Written by: Astaf'ev Sergey <seryymail@mail.ru>
# This is a part of RBOINC R package
# Copyright (c) 2022 Karelian Research Centre of
# the RAS: Institute of Applied Mathematical Researh
# All rights reserved

emerge-webrsync
#emerge --sync
emerge --verbose --update --deep --changed-use --newuse @world

cd `dirname ${BASH_SOURCE[0]}`

./update_packages.R
rm -r /home/boinc/R
su boinc -c 'Rscript -e "dir.create(Sys.getenv(\"R_LIBS_USER\"), FALSE, TRUE)"'
./prepare_release.sh
