#!/bin/bash
# Original file name: "get_file_prefix.sh"
# Created: 2021.02.05
# Last modified: 2021.02.11
# License: BSD-3-clause
# Written by: Astaf'ev Sergey <seryymail@mail.ru>
# This is a part of RBOINC R package.
# Copyright (c) 2021-2022 Karelian Research Centre of
# the RAS: Institute of Applied Mathematical Research
# All rights reserved

# Get unique name for saving file.
echo '<?php include("'`dirname ${BASH_SOURCE[0]}`'/prefix.inc");echo get_file_prefix();?>' | php
