# Original file name: "fileUploading.R"
# Created: 2021.02.03
# Last modified: 2021.07.23
# License: BSD-3-clause
# Written by: Astaf'ev Sergey <seryymail@mail.ru>
# This is a part of RBOINC R package.
# Copyright (c) 2021 Karelian Research Centre of the RAS:
# Institute of Applied Mathematical Research
# All rights reserved

#' @importFrom ssh scp_upload
#' @importFrom ssh ssh_exec_wait

upload_work_ssh = function(connection, path_to_archive)
{
  # Create directory for arhive
  file_prefix = ""
  ssh_exec_wait(connection$connection,
                paste0(connection$dir, "/rboinc/bin/get_file_prefix.sh"),
                function(str){file_prefix <<- rawToChar(str)})
  upload_dir = paste0(connection$dir, "/rboinc/uploads/", file_prefix)
  ssh_exec_wait(connection$connection, paste0("mkdir ", upload_dir))
  # upload archive
  scp_upload(connection$connection,
             path_to_archive,
             paste0(upload_dir, "/work.tar.xz"), verbose=FALSE)
  # unpack archive
  ssh_exec_wait(connection$connection,
                paste0("cd ", upload_dir, " && tar -xf ./work.tar.xz && rm work.tar.xz"))
  return(list(upload_dir = upload_dir, file_prefix = file_prefix))
}

make_unique_file_names_ssh = function(connection, upload_info, data_count)
{
  data = vector("list", data_count)
  files_prefix = upload_info$file_prefix
  path = upload_info$upload_dir
  ssh_exec_wait(connection$connection,
                paste0("mv ", path, "/common.tar.xz ", path , "/", files_prefix, "common.tar.xz"))
  for(k in 0:(data_count-1)){
    old_name = paste0(path, "/data/", k, ".rda")
    new_name = paste0(path, "/data/",files_prefix, k, ".rda")
    data[[k+1]] = paste0(files_prefix, k, ".rda")
    ssh_exec_wait(connection$connection, paste0("mv ", old_name, " ", new_name))
  }
  return(list(data=data, common = paste0(files_prefix, "common.tar.xz")))
}

stage_files_ssh = function(connection, path_to_archive, data_count)
{
  upload_info = upload_work_ssh(connection, path_to_archive)
  files = make_unique_file_names_ssh(connection, upload_info, data_count)
  ssh_exec_wait(connection$connection,
                paste0("cd ", connection$dir, " && " , "./bin/stage_file ", upload_info$upload_dir))
  ssh_exec_wait(connection$connection,
                paste0("cd ", connection$dir, " && " , "./bin/stage_file ", upload_info$upload_dir, "/data"))
  ssh_exec_wait(connection$connection, paste0("rm -r ", upload_info$upload_dir))
  return(files)
}
