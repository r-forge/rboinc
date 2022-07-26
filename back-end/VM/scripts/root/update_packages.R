#!/usr/bin/Rscript
# Original file name: "update_packages.R"
# Created: 2022.07.22
# Last modified: 2022.07.22
# License: BSD-3-clause
# Written by: Astaf'ev Sergey <seryymail@mail.ru>
# This is a part of RBOINC R package
# Copyright (c) 2022 Karelian Research Centre of
# the RAS: Institute of Applied Mathematical Researh
# All rights reserved

update.packages(repos = "https://cloud.r-project.org", ask = FALSE)

packages = c("BiocManager", "parallel", "doParallel", "foreach")
for(val in packages){
    if(!require(val)){
        install.packages(val, repos = "https://cloud.r-project.org")
    }
}
BiocManager::install(ask = FALSE)
