# Original file name: "finalize_enter.sh"
# Created: 2022.07.15
# Last modified: 2022.07.15
# License: BSD-3-clause
# Written by: Astaf'ev Sergey <seryymail@mail.ru>
# This is a part of RBOINC R package
# Copyright (c) 2022 Karelian Research Centre of
# the RAS: Institute of Applied Mathematical Researh
# All rights reserved
# Add this to x<32|64>/root/.bashrc

source /etc/profile

if [ -d /lib64 ];
then
    export PS1="(x64) ${PS1}"
else
    export PS1="(x32) ${PS1}"
fi
