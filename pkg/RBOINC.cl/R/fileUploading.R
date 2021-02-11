# Original file name: "fileUploading.R"
# Created: 2021.02.03
# Last modified: 2021.02.11
# License: Comming soon
# Written by: Astaf'ev Sergey <seryymail@mail.ru>
# This is a part of RBOINC R package.

#' @importFrom ssh scp_upload
#' @importFrom ssh ssh_exec_wait

upload_work = function(connection, path_to_archive)
{
  # Create directory for arhive
  ssh_exec_wait(connection$connection, "mkdir -p ~/.rboinc_cache")
  dir_name = ""
  ssh_exec_wait(connection$connection, "date +\"%G_%m_%d_%I_%M_%S_%N\"", function(str){dir_name <<- rawToChar(str[1:(length(str)-1)])})
  serv_dir = paste0("~/.rboinc_cache/", dir_name)
  ssh_exec_wait(connection$connection, paste0("mkdir ",serv_dir))
  # upload archive
  scp_upload(connection$connection, path_to_archive, paste0(serv_dir, "/work.tar.xz"), verbose=FALSE)
  # unpack archive
  ssh_exec_wait(connection$connection, paste0("cd ",serv_dir, " && tar -xf ./work.tar.xz && rm work.tar.xz"))
  return(serv_dir)
}

make_unique_file_names = function(connection, path, data_count)
{
  data = vector("list", data_count)
  files_prefix = ""
  cmd_line = paste0(connection$dir, "/rboinc/bin/get_file_prefix.sh")
  ssh_exec_wait(connection$connection, cmd_line, function(str){files_prefix <<- rawToChar(str)})
  ssh_exec_wait(connection$connection, paste0("mv ", path, "/common.tar.xz ", path , "/", files_prefix, "common.tar.xz"))
  for(k in 0:(data_count-1)){
    old_name = paste0(path, "/data/", k, ".rbs")
    new_name = paste0(path, "/data/",files_prefix, k, ".rbs")
    data[[k+1]] = paste0(files_prefix, k, ".rbs")
    ssh_exec_wait(connection$connection, paste0("mv ", old_name, " ", new_name))
  }
  return(list(data=data, common = paste0(files_prefix, "common.tar.xz")))
}

stage_files = function(connection, path_to_archive, data_count)
{
  serv_path = upload_work(connection, path_to_archive)
  files = make_unique_file_names(connection, serv_path, data_count)
  ssh_exec_wait(connection$connection, paste0("cd ", connection$dir, " && " , "./bin/stage_file ", serv_path))
  ssh_exec_wait(connection$connection, paste0("cd ", connection$dir, " && " , "./bin/stage_file ", serv_path, "/data"))
  ssh_exec_wait(connection$connection, paste0("rm -r ", serv_path))
  return(files)
}
