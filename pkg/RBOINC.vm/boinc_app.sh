#!/bin/bash
echo "BOINC application will be started in 3 second. Press Ctrl-C to abort it."
sleep 3
echo "Starting BOINC application..."
cp -r ~/shared/* ~/workdir/
cd ~/workdir
tar -xf common.tar.xz
mkdir -p files
Rscript code.R
cp result.rbs ~/shared/result.rbs
echo "Shutdowning..."
shutdown -hP now
