#!/bin/bash
# Original file name: "prepare_disk.sh"
# Created: 2022.07.18
# Last modified: 2022.07.21
# License: BSD-3-clause
# Written by: Astaf'ev Sergey <seryymail@mail.ru>
# This is a part of RBOINC R package
# Copyright (c) 2022 Karelian Research Centre of
# the RAS: Institute of Applied Mathematical Researh
# All rights reserved

echo -e "mklabel gpt\nunit MiB\nmkpart primary 1 ${2}\nmkpart primary ${2} -1\nquit" | parted ${1}
parted ${1} < ./data/parted.in
mkfs.ext2 -N 100 ${1}1
mkswap ${1}2
dd bs=440 conv=notrunc count=1 if=/usr/share/syslinux/gptmbr.bin of=${1}
mount ${1}1 /mnt
mkdir /mnt/extlinux
extlinux --install /mnt/extlinux
#ln -snf . /mnt/boot
