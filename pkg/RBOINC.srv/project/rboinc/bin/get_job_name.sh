#!/bin/bash
# Original file name: "get_job_name.sh"
# Created: 2021.02.05
# Last modified: 2021.02.05
# License: Comming soon
# Written by: Astaf'ev Sergey <seryymail@mail.ru>
# This is a part of RBOINC R package.

# Get unique name for job file.
echo '<?php include("'`dirname ${BASH_SOURCE[0]}`'/prefix.inc");echo get_job_name();?>' | php
