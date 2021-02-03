# Original file name: "fileUploading.R"
# Created: 2021.02.03
# Last modified: 2021.02.03
# License: Comming soon
# Written by: Astaf'ev Sergey <seryymail@mail.ru>
# This is a part of RBOINC R package.

#' @importFrom ssh scp_upload
#' @importFrom ssh ssh_exec_wait
upload_work = function(connection, pathToArchive)
{
  # Create directory for arhive
  ssh_exec_wait(connection$connection, "mkdir -p ~/.rboinc_cache")
  dir_name = ""
  ssh_exec_wait(connection$connection, "date +\"%G_%m_%d_%I_%M_%S\"", function(str){dir_name <<- rawToChar(str[1:(length(str)-1)])})
  serv_dir = paste0("~/.rboinc_cache/", dir_name)
  ssh_exec_wait(connection$connection, paste0("mkdir ",serv_dir))
  # upload archive
  scp_upload(connection$connection, pathToArchive, paste0(serv_dir, "/work.tar.xz"), verbose=FALSE)
  # unpack archive
  ssh_exec_wait(connection$connection, paste0("cd ",serv_dir, " && tar -xf ./work.tar.xz && rm work.tar.xz"))
  return(serv_dir)
}


library(ssh)
con = create_connection(host = "boincadm@boinc-server.local", dir ="~/projects/myproject")

dat = list(c(1,2,3), c(1.2,2.4,3.6))
fun = function(val)
{
  return(val*2.5+3)
}

archive = make_archive(fun, dat, files="NAMESPACE")
archive

upload_work(con, archive)

close_connection(con)
