# Original file name: "makeArchive.R"
# Created: 2021.02.03
# Last modified: 2021.11.22
# License: BSD-3-clause
# Written by: Astaf'ev Sergey <seryymail@mail.ru>
# This is a part of RBOINC R package.
# Copyright (c) 2021 Karelian Research Centre of the RAS:
# Institute of Applied Mathematical Research
# All rights reserved

#' @importFrom utils tar

generate_r_script = function(original_work_func_name, init, glob_vars, packages)
{
  # doMC is not supported on Windows. This package can be installed, but it
  # cannot provide multiprocessing under Windows. Instead, the code using doMC
  # will be executed in one thread. This script tries to install it because
  # testAPI.R needs this package.
  str = "library(doParallel)\nlibrary(foreach)\nlibrary(parallel)\n"
  for(val in packages){
    str = paste0(str, "if(!require(", val, ")){\n\tinstall.packages(\"", val, "\", repos = c('http://rforge.net', 'http://cran.rstudio.org'))\n",
                 "  library(", val, ")\n}\n")
  }
  str = paste0(str, "load(\"code.rda\")\n")
  str = paste0(str, "load(\"data.rda\")\n")
  str = paste0(str, "setwd(\"./files/\")\n")
  str = paste0(str, "RBOINC_cluster = makeCluster(detectCores())\n")
  str = paste0(str, "registerDoParallel(RBOINC_cluster)\n")
  str = paste0(str, original_work_func_name, " = RBOINC_work_func\n")
  if(!is.null(glob_vars)){
    str = paste0(str, "list2env(RBOINC_global_vars, .GlobalEnv)\n")
  }
  if(!is.null(init)){
    str = paste0(str, "RBOINC_init_func()\n")
  }
  str = paste0(str, "result = foreach(value = RBOINC_data")
  if(length(packages) > 0){
    str = paste0(str, ", .packages = c(\"")
    str = paste0(str, paste(packages, collapse = "\", \""))
    str = paste0(str, "\")")
  }
  str = paste0(str, ", .export = c(\"RBOINC_work_func\"",
               ", \"", original_work_func_name,"\"")
  if(!is.null(glob_vars)){
    str = paste0(str, ", \"RBOINC_global_vars\"")
  }
  str = paste0(str, ")) %dopar% {\n")
  if(!is.null(glob_vars)){
    str = paste0(str, "  list2env(RBOINC_global_vars, .GlobalEnv)\n")
  }
  str = paste0(str, "  return(list(res = RBOINC_work_func(value$val), pos = value$pos))\n")
  str = paste0(str, "}\n")
  str = paste0(str, "setwd(\"../../shared/\")\n")
  str = paste0(str, "save(result, file = \"result.rda\", compress = \"xz\", compression_level = 9)\n")
  str = paste0(str, "stopCluster(RBOINC_cluster)\n")
  return(str)
}

make_dirs = function()
{
  tmp_dir = tempdir()
  tmp_dir = paste0(tmp_dir, "/rboinc-work")
  dir.create(tmp_dir)
  dir.create(paste0(tmp_dir, "/files"))
  dir.create(paste0(tmp_dir, "/data"))
  return(tmp_dir)
}

make_archive = function(RBOINC_work_func,
                        original_work_func_name,
                        data,
                        RBOINC_init_func = NULL,
                        RBOINC_global_vars = NULL,
                        packages = c(),
                        files = c())
{
  if(!is.list(data)){
    return(NULL)
  }
  # Create temporary dir for archive
  tmp_dir = make_dirs()
  # Save funcions and global vars
  obj_list = c("RBOINC_work_func")
  if(!is.null(RBOINC_init_func)){
    obj_list = cbind(obj_list, "RBOINC_init_func")
  }
  if(!is.null(RBOINC_global_vars)){
    obj_list = cbind(obj_list, "RBOINC_global_vars")
  }
  save(list = obj_list, file = paste0(tmp_dir, "/code.rda"))
  # save code
  out = file(paste0(tmp_dir, "/code.R"))
  writeLines(generate_r_script(original_work_func_name, RBOINC_init_func, RBOINC_global_vars, packages), out)
  close(out)
  # Copy files
  files_dir = paste0(tmp_dir, "/files/")
  for(val in files){
    tryCatch(
      file.copy(val, files_dir, recursive=TRUE),
    error = function(mess){
      stop(paste0("Archive making error: \"", mess, "\""))
    }, warning = function(mess){
      stop(paste0("Archive making error: \"", mess, "\""))
    })
  }
  # write data
  data_dir = paste0(tmp_dir, "/data/")
  num = 0
  for(RBOINC_data in data){
    save(RBOINC_data, file = paste0(data_dir, num, ".rda"))
    num = num + 1
  }
  if(file.exists(paste0(tmp_dir, "/../rboinc-work.tar.xz"))){
    unlink(paste0(tmp_dir, "/../rboinc-work.tar.xz"))
  }
  # create archive
  archive_path = paste0(tempfile(), ".tar.xz")
  old_wd = getwd()
  on.exit(setwd(old_wd), TRUE)
  setwd(tmp_dir)
  tryCatch({
    tar(paste0(tmp_dir, "/common.tar.xz"),c("code.rda", "code.R", "files"), compression="xz")
    tar(archive_path, c("common.tar.xz", "data"), compression="xz")
  }, error = function(mess){
    stop(paste0("Archive making error: \"", mess, "\""))
  }
  )
  # delete files and return path to archive
  unlink(tmp_dir, recursive = TRUE)
  return(archive_path)
}
