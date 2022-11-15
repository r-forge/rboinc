#!/usr/bin/Rscript
# Original file name: "make_release.R"
# Created: 2022.07.22
# Last modified: 2022.11.15
# License: BSD-3-clause
# Written by: Astaf'ev Sergey <seryymail@mail.ru>
# This is a part of RBOINC R package
# Copyright (c) 2022 Karelian Research Centre of
# the RAS: Institute of Applied Mathematical Researh
# All rights reserved
library(parallel)

# Write your packages here:
packages = c()

for(val in packages){
    if(!require(val)){
        BiocManager::install(val, Ncpus = detectCores(), ask = FALSE)
    }
}
BiocManager::install(Ncpus = detectCores(), ask = FALSE, checkBuilt = TRUE)
