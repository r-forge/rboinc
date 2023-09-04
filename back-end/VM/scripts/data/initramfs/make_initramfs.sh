#!/bin/bash
# Original file name: "make_initramfs.sh"
# Created: 2022.07.18
# Last modified: 2023.06.23
# License: BSD-3-clause
# Written by: Astaf'ev Sergey <seryymail@mail.ru>
# This is a part of RBOINC R package
# Copyright (c) 2022-2023 Karelian Research Centre of
# the RAS: Institute of Applied Mathematical Researh
# All rights reserved

tmpd=$(mktemp -d)
toold=$(pwd)

rm ../initramfs-${1}.cpio.zst
rm ../initramfs-${1}.cpio
cd $tmpd

# Building fs structure:
tar -xf ${toold}/busybox-${1}.tar.xz
mkdir -p bin dev etc lib/modules mnt/sfs mnt/boot mnt/tmp mnt/root opt proc root run sbin sys tmp usr var/lib
cp -a ${toold}/../../../${1}/dev/* ./dev/
# hdx driver is no longer supported:
rm dev/hd*

# Copying init files:
cp ${toold}/fstab ./etc/fstab
rm init
cp ${toold}/init ./init

# Building initramfs image:
find . -print0 | cpio --null --create --format=newc > ${toold}/../initramfs-${1}.cpio
zstd --ultra -22 -k ${toold}/../initramfs-${1}.cpio -o ${toold}/../initramfs-${1}.cpio.zst
cd ${toold}
rm -r ${tmpd}

