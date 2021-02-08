# Original file name: "getResult.R"
# Created: 2021.02.08
# Last modified: 2021.02.08
# License: Comming soon
# Written by: Astaf'ev Sergey <seryymail@mail.ru>
# This is a part of RBOINC R package.

#' @importFrom ssh ssh_exec_wait
#' @importFrom ssh scp_download
#' @importFrom pracma strcmp

#' @export update_jobs_status

download_result = function(connection, file, job_name)
{
  tmp_dir = tempdir(TRUE)
  #print(paste0(connection$dir, "/", file))
  scp_download(connection$connection, paste0(connection$dir, "/", file), tmp_dir)
  load(paste0(tmp_dir, "/", job_name))
  # variable result was loaded from tmp_file
  return(result)
}

#' @title update_jobs_status
#' @description Update status for jobs and get result for complete jobs.
#' @param connection a connection created by create_connection.
#' @param jobs_status a list returned by create_jobs or update_jobs_status.
#' @return a string vector with jobs names
update_jobs_status = function(connection, jobs_status)
{
  for(k in 1:length(jobs_status$jobs_name)){
    cmd_line = paste0("cd ", connection$dir, " && ./rboinc/bin/get_job_state.php ", jobs_status$jobs_name[[k]])
    mess = ""
    job_state = ssh_exec_wait(connection$connection, cmd_line, function(str){mess <<- rawToChar(str)})
    if ((job_state == 0) && (jobs_status$jobs_code[k] != 0)){
      jobs_status$jobs_status[k] = "complete"
      jobs_status$results[[k]] = download_result(connection, mess, jobs_status$jobs_name[k])
    }else{
      jobs_status$jobs_status[k] = mess
    }
    jobs_status$jobs_code[k] = job_state
  }
  jobs_status$status = "complete"
  for(val in jobs_status$jobs_code){
    if((val == 6) && (!strcmp(jobs_status$status, "error"))){
      jobs_status$status = "computation"
    } else if(val != 0){
      jobs_status$status = "error"
    }
  }
  return(jobs_status)
}
