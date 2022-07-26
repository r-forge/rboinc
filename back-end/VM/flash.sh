#!/bin/bash
# Original file name: "flash.sh"
# Created: 2022.07.21
# Last modified: 2022.07.21
# License: BSD-3-clause
# Written by: Astaf'ev Sergey <seryymail@mail.ru>
# This is a part of RBOINC R package
# Copyright (c) 2022 Karelian Research Centre of
# the RAS: Institute of Applied Mathematical Researh
# All rights reserved

if [ "${1}" != "x32" ] && [ "${1}" != "x64" ] && [ $# != 2 ];
then
    echo "Usage ${0} <x32|x64> </dev/sdx>"
    exit 1
fi

# Making rootfs image:
btrfs subvolume snapshot -r ${1} ${1}-full
./enter.sh ${1} '/root/scripts/make_release.sh "I_am_running_from_script." "Yes,I_am_exactly_running_from_script!!!"'
img_dir=$(mktemp -d)
mksquashfs /root/${1}/ ${img_dir}/fs.sfs -comp zstd -Xcompression-level 22
btrfs subvolume delete ${1}
mv ${1}-full ${1}
btrfs property set ${1} ro false

# Disk partition:
size=$(wc -c ${img_dir}/fs.sfs | awk '{print $1}')
size=$(echo "${size}*103/100/1024/1024+10" | bc)
echo size
cd scripts
./prepare_disk.sh $2 $size

# Copying files:
mv ${img_dir}/fs.sfs /mnt/
./install_kernel.sh $1

# Free resources:
rm -r ${img_dir}
umount /mnt
