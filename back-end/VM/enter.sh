#!/bin/bash
# Original file name: "enter.sh"
# Created: 2022.07.18
# Last modified: 2022.07.22
# License: BSD-3-clause
# Written by: Astaf'ev Sergey <seryymail@mail.ru>
# This is a part of RBOINC R package
# Copyright (c) 2022 Karelian Research Centre of
# the RAS: Institute of Applied Mathematical Researh
# All rights reserved

if [ "${1}" != "x32" ] && [ "${1}" != "x64" ] || [ $# -gt 2 ];
then 
    echo "Usage: ${0} <x32|x64> <optional command>"
    exit 1
fi

if [ $# = 2 ]; then
    run=$2
else
    run="/bin/bash"
fi


echo Mounting pseudo-fs...
mount --types proc /proc /root/${1}/proc
mount --rbind /sys /root/${1}/sys
mount --make-rslave /root/${1}/sys
mount --rbind /dev /root/${1}/dev
mount --make-rslave /root/${1}/dev
mount --bind /run /root/${1}/run
mount --make-slave /root/${1}/run
mount --bind /root/scripts/root /root/${1}/root/scripts
cp --dereference /etc/resolv.conf /root/${1}/etc

echo Chrooting to ${1}...
chroot /root/${1} $run

echo Unmounting pseudo-fs ...
umount -l /root/${1}/dev{/shm,/pts,}
umount /root/${1}/proc
umount -R /root/${1}/sys
umount /root/${1}/run
umount /root/${1}/root/scripts
