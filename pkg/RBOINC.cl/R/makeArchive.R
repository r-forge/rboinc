# Original file name: "makeArchive.R"
# Created: 2021.02.03
# Last modified: 2021.02.09
# License: Comming soon
# Written by: Astaf'ev Sergey <seryymail@mail.ru>
# This is a part of RBOINC R package.

generate_r_script = function(func, init, glob_vars, packages)
{
  str = ""
  for(val in packages){
    str = paste0(str, "library(", val, ")\n")
  }
  str = paste0(str, "load(\"code.rbs\")\n")
  str = paste0(str, "load(\"data.rbs\")\n")
  str = paste0(str, "setwd(\"./files/\")\n")
  if(!is.null(glob_vars)){
    str = paste0(str, "list2env(RBOINC_global_vars, .GlobalEnv)\n")
  }
  if(!is.null(init)){
    str = paste0(str, "RBOINC_init_func()\n")
  }
  str = paste0(str, "result = RBOINC_work_func(RBOINC_data)\n")
  str = paste0(str, "setwd(\"../\")\n")
  str = paste0(str, "save(result, file = \"result.rbs\")\n")
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

make_archive = function(RBOINC_work_func, data, RBOINC_init_func = NULL, RBOINC_global_vars = NULL, packages = c(), files = c())
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
  save(list = obj_list, file = paste0(tmp_dir, "/code.rbs"))
  # save code
  out = file(paste0(tmp_dir, "/code.R"))
  writeLines(generate_r_script(RBOINC_work_func, RBOINC_init_func, RBOINC_global_vars, packages), out)
  close(out)
  # Copy files
  files_dir = paste0(tmp_dir, "/files/")
  for(val in files){
    file.copy(val, files_dir, recursive=TRUE)
  }
  # write data
  data_dir = paste0(tmp_dir, "/data/")
  num = 0
  for(RBOINC_data in data){
    save(RBOINC_data, file = paste0(data_dir, num, ".rbs"))
    num = num + 1
  }
  if(file.exists(paste0(tmp_dir, "/../rboinc-work.tar.xz"))){
    unlink(paste0(tmp_dir, "/../rboinc-work.tar.xz"))
  }
  # create archive
  archive_path = paste0(tempfile(), ".tar.xz")
  old_wd = getwd()
  setwd(tmp_dir)
  tar(paste0(tmp_dir, "/common.tar.xz"),c("code.rbs", "code.R", "files"))
  tar(archive_path, c("common.tar.xz", "data"), compression="xz")
  setwd(old_wd)
  # delete files and return path to archive
  unlink(tmp_dir, recursive = TRUE)
  return(archive_path)
}
