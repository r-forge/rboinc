# Original file name: "makeArchive.R"
# Created: 2021.02.03
# Last modified: 2022.01.27
# License: BSD-3-clause
# Written by: Astaf'ev Sergey <seryymail@mail.ru>
# This is a part of RBOINC R package.
# Copyright (c) 2021-2022 Karelian Research Centre of
# the RAS: Institute of Applied Mathematical Research
# All rights reserved


gen_r_scripts = function(original_work_func_name, init, glob_vars, packages, install_func, is_NULL_data, max_data_count)
{
  # First, create install script
  inst = ""
  if(!is.null(packages)){
    repos = "c("
    for(val in options('repos')$repos){
      if(startsWith(val, "http") || startsWith(val, "ftp")){
        repos = paste0(repos, "'", val, "', ")
      }
    }
    # Add default mirror:
    repos = paste0(repos, "'https://cloud.r-project.org')")
    #create a folder for the installed packages just in case:
    inst = "dir.create(Sys.getenv('R_LIBS_USER'), FALSE, TRUE)\n"
    # package installing:
    for(val in packages){
      inst = paste0(inst,
      "if(!require(", val, ")){\n",
      "  install.packages('", val, "', lib = Sys.getenv('R_LIBS_USER'), repos = ", repos, ")\n",
      "}\n")
    }
    if(!is.null(install_func)){
      inst = paste0(inst,
      "RBOINC_not_installed = setdiff(c('", paste(packages, collapse = "', '"),"'), installed.packages()[,1])\n",
      "load('code.rda')\n",
      "RBOINC_additional_inst_func(RBOINC_not_installed)\n")
    }
  }
  # Second, create job script
  # Load libraries
  if((!is_NULL_data) && (max_data_count > 1)){
    str = paste0(
    "library('doParallel')\n",
    "library('foreach')\n",
    "library('parallel')\n")
  }else {
    str = ""
  }
  for(val in packages){
    str = paste0(str,
    "library('", val, "')\n")
  }
  str = paste0(str,
    "load('code.rda')\n",
    "load('data.rda')\n",
    "setwd('./files/')\n")
  if((!is_NULL_data) && (max_data_count > 1)){
    str = paste0(str,
    "RBOINC_cluster = makeCluster(detectCores())\n",
    "registerDoParallel(RBOINC_cluster)\n")
  }
  if(!is.null(glob_vars)){
    str = paste0(str,
    "list2env(RBOINC_global_vars, .GlobalEnv)\n")
  }
  if(!is.null(init) && (!is_NULL_data) && (max_data_count > 1)){
    str = paste0(str,
    "clusterExport(RBOINC_cluster, ls(globalenv()))\n",
    "RBOINC_pseudo_init_func = function (RBOINC_procnum)\n",
    "{\n")
    for(val in packages){
      str = paste0(str,
    "  library('", val, "')\n")
    }
    str = paste0(str,
    "  RBOINC_init_func()\n",
    "}\n",
    "clusterCall(cl = RBOINC_cluster, fun =  RBOINC_pseudo_init_func, detectCores())\n")
  } else if(!is.null(init)){
    str = paste0(str,
    "RBOINC_init_func()\n")
  }
  if((!is_NULL_data) && (max_data_count > 1)){
    str = paste0(str, "result = foreach(value = RBOINC_data")
    if(length(packages) > 0){
      str = paste0(str, ", .packages = c('")
      str = paste0(str, paste(packages, collapse = "', '"))
      str = paste0(str, "')")
    }
    str = paste0(str, ") %dopar% {\n")
    str = paste0(str,
    "  ",original_work_func_name, " = RBOINC_work_func\n",
    "  return(list(res = RBOINC_work_func(value$val), pos = value$pos))\n",
    "}\n")
  } else if(is_NULL_data) {
    str = paste0(str,
    original_work_func_name, " = RBOINC_work_func\n",
    "result = list(list(res = RBOINC_work_func(), ",
                       "pos = RBOINC_data[[1]]$pos))\n")
  } else{
    str = paste0(str,
    original_work_func_name, " = RBOINC_work_func\n",
    "result = list(list(res = RBOINC_work_func(RBOINC_data[[1]]$val),",
                       "pos = RBOINC_data[[1]]$pos))\n")
  }
  str = paste0(str,
    "setwd('../../shared/')\n",
    "save(result, file='result.rda', compress='xz', compression_level = 9)\n")
  if((!is_NULL_data) && (max_data_count > 1)){
    str = paste0(str,
    "stopCluster(RBOINC_cluster)\n")
  }
  return(list(code = str, install = inst))
}

make_dirs = function()
{
  tmp_dir = tempdir()
  tmp_dir = paste0(tmp_dir, "/rboinc-work")
  if(dir.exists(tmp_dir)){
    unlink(tmp_dir, recursive = TRUE, force = TRUE)
  }
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
                        files = c(),
                        RBOINC_additional_inst_func = NULL,
                        is_NULL_data)
{
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
  if(!is.null(RBOINC_additional_inst_func)){
    obj_list = cbind(obj_list, "RBOINC_additional_inst_func")
  }
  save(list = obj_list, file = paste0(tmp_dir, "/code.rda"))
  # save code
  scripts = gen_r_scripts(original_work_func_name, RBOINC_init_func,
                          RBOINC_global_vars, packages,
                          RBOINC_additional_inst_func,
                          is_NULL_data, data$max_len)
  out = file(paste0(tmp_dir, "/code.R"))
  writeLines(scripts$code, out)
  close(out)
  if(scripts$install != ""){
    out = file(paste0(tmp_dir, "/install.R"))
    writeLines(scripts$install, out)
    close(out)
  }
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
  for(RBOINC_data in data$data){
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
    if(scripts$install == ""){
      virtual_compress(paste0(tmp_dir, "/common.tar.xz"),
                       c("code.rda", "code.R", "files"))
    } else {
      virtual_compress(paste0(tmp_dir, "/common.tar.xz"),
                       c("code.rda", "code.R", "install.R", "files"))
    }
    virtual_compress(archive_path, c("common.tar.xz", "data"))
  }, error = function(mess){
    stop(paste0("Archive making error: '", mess, "'"))
  }
  )
  # delete files and return path to archive
  setwd(old_wd)
  unlink(tmp_dir, recursive = TRUE, force = TRUE)
  return(archive_path)
}
