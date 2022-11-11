#!/bin/bash
# Original file name: "fix_libs.sh"
# Created: 2022.11.10
# Last modified: 2022.11.10
# License: BSD-3-clause
# Written by: Astaf'ev Sergey <seryymail@mail.ru>
# This is a part of RBOINC R package
# Copyright (c) 2022 Karelian Research Centre of
# the RAS: Institute of Applied Mathematical Researh
# All rights reserved

emerge @preserved-rebuild
revdep-rebuild

R_REPO=$(Rscript -e 'cat(.libPaths()[1])')

find $R_REPO -iname "*.so*" | while read lib_path; do
	if ldd -r "$lib_path" 2>&1 | grep -qF "undefined symbol"; then
		echo "Fixing: $lib_path"
		pkg_name=$(basename `dirname $(dirname $lib_path)`)
		Rscript -e 'BiocManager::install("$pkg_name", ask = FALSE)'
	fi
done
