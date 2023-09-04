#!/bin/bash
# Original file name: "boinc_app.sh"
# Created: 2022.07.18
# Last modified: 2023.06.23
# License: BSD-3-clause
# Written by: Astaf'ev Sergey <seryymail@mail.ru>
# This is a part of RBOINC R package
# Copyright (c) 2022-2023 Karelian Research Centre of
# the RAS: Institute of Applied Mathematical Researh
# All rights reserved

kname=$(basename `find ../${1}/boot -name "vmlinuz*" -printf "%T@ %p\n" | sort -r | sed "s/^[^ ]* //"`)
echo Installing ${kname}...
cp ../${1}/boot/${kname} /mnt/
# Build initramfs if needed
if [ ! -f "./data/initramfs-${1}.cpio.zst" ]; then
    cd ./data/initramfs
    ./make_initramfs.sh ${1}
    cd ../..
fi
#Install initramfs only if it is not passed via kernel config:
needInitramfs=$(cat ../${1}/usr/src/linux/.config | grep CONFIG_INITRAMFS_SOURCE=\"\")
if [ ! -z "${needInitramfs}" ]; then
    cp ./data/initramfs-${1}.cpio.zst /mnt/
fi
cp ./data/syslinux.cfg /mnt/
#mkdir /mnt/tmp /mnt/sfs /mnt/root
echo "    LINUX /${kname}" >> /mnt/syslinux.cfg
if [ ! -z "${needInitramfs}" ]; then
    echo "    INITRD /initramfs-${1}.cpio.zst" >> /mnt/syslinux.cfg
fi

