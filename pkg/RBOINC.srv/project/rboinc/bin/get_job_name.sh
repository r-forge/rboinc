#!/bin/bash
# Original file name: "get_job_name.sh"
# Created: 2021.02.05
# Last modified: 2021.02.05
# License: Comming soon
# Written by: Astaf'ev Sergey <seryymail@mail.ru>
# This is a part of RBOINC R package.

# Get unique number for saving file.
TMP=`dirname ${BASH_SOURCE[0]}`/get_next_number.php
echo rboinc_`date +%G%m%d%I%M%S.%N`.`$TMP job_number.count`
