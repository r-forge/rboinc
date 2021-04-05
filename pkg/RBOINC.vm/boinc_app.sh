#!/bin/bash
# Original file name: "boinc_app.sh"
# Created: 2021.02.05
# Last modified: 2021.03.29
# License: BSD-3-clause
# Written by: Astaf'ev Sergey <seryymail@mail.ru>
# This is a part of RBOINC R package.
# Copyright (c) 2021 Karelian Research Centre of the RAS:
# Institute of Applied Mathematical Research
# All rights reserved

echo "BOINC application will be started in 1 second. Press Ctrl-C to abort it."
sleep 1
echo "Starting BOINC application..."
cp -r ~/shared/* ~/workdir/
cd ~/workdir
tar -xf common.tar.xz
mkdir -p files
Rscript code.R
#cp result.rbs ~/shared/result.rbs
echo "Shutdowning..."
shutdown -hP now
