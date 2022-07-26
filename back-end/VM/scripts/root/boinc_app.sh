#!/bin/bash
# Original file name: "boinc_app.sh"
# Created: 2021.02.05
# Last modified: 2022.07.21
# License: BSD-3-clause
# Written by: Astaf'ev Sergey <seryymail@mail.ru>
# This is a part of RBOINC R package.
# Copyright (c) 2021-2022 Karelian Research Centre of
# the RAS: Institute of Applied Mathematical Research
# All rights reserved

echo "BOINC application will be started in 1 second. Press Ctrl-C to abort it."
sleep 1
echo "Starting BOINC application..."
mkdir ~/shared/workdir
cd ~/shared/
mv data.rda workdir
cd workdir
tar -xf ../common.tar.xz
mkdir -p files
Rscript install.R
Rscript code.R
echo "Shutdowning..."
shutdown -hP now
