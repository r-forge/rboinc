#!/bin/bash
# Original file name: "boinc_app.sh"
# Created: 2022.07.18
# Last modified: 2022.07.21
# License: BSD-3-clause
# Written by: Astaf'ev Sergey <seryymail@mail.ru>
# This is a part of RBOINC R package
# Copyright (c) 2022 Karelian Research Centre of
# the RAS: Institute of Applied Mathematical Researh
# All rights reserved

kname=$(basename `find ../${1}/boot -name "vmlinuz*" -printf "%T@ %p\n" | sort -r | sed "s/^[^ ]* //"`)
echo Installing ${kname}...
cp ../${1}/boot/${kname} /mnt/
if [ ! -f "./data/initramfs-${1}.cpio.zst" ]; then
    cd ./data/initramfs
    ./make_initramfs.sh ${1}
    cd ../..
fi
cp ./data/initramfs-${1}.cpio.zst /mnt/
cp ./data/syslinux.cfg /mnt/
#mkdir /mnt/tmp /mnt/sfs /mnt/root
echo "    LINUX /${kname}" >> /mnt/syslinux.cfg
echo "    INITRD /initramfs-${1}.cpio.zst" >> /mnt/syslinux.cfg

