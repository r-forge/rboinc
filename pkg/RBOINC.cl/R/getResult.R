# Original file name: "getResult.R"
# Created: 2021.02.08
# Last modified: 2021.07.20
# License: BSD-3-clause
# Written by: Astaf'ev Sergey <seryymail@mail.ru>
# This is a part of RBOINC R package.
# Copyright (c) 2021 Karelian Research Centre of the RAS:
# Institute of Applied Mathematical Research
# All rights reserved

#' @importFrom ssh ssh_exec_wait
#' @importFrom ssh scp_download
#' @importFrom httr GET
#' @importFrom httr POST
#' @importFrom httr cookies
#' @importFrom httr write_disk
#' @importFrom xml2 as_list

#' @export update_jobs_status

download_result = function(connection, file, job_name, callback_function)
{
  tmp_dir = tempdir(TRUE)
  file_name = paste0(tmp_dir, "/", job_name)
  if(connection$type == "ssh"){
    scp_download(connection$connection,
                 paste0(connection$dir, "/", file),
                 tmp_dir,
                 verbose = FALSE)
  }else if(connection$type == "http"){
    for(k in 1:5){
      donwload_res = GET(file, write_disk(file_name, overwrite=TRUE))
      # Fix for BOINC bug. The server reports on a successful job completion
      # earlier than copies the file to the result folder. Sometimes it
      # temporarily leads to error 404.
      if (donwload_res$status_code == 404){
        Sys.sleep(1)
      } else {
        break
      }
    }
  }
  # fix for potential vulnerability
  tmpenv = new.env()
  load(file_name, tmpenv)
  unlink(file_name)
  # return raw or processed result
  if(is.null(callback_function)){
    return(tmpenv$result)
  } else {
    for (k in seq_len(length(tmpenv$result))){
      tmpenv$result[[k]]$res = callback_function(tmpenv$result[[k]]$res)
    }
    return(callback_function(tmpenv$result))
  }
}

#' @title update_jobs_status
#' @description Update status for jobs and get result for complete jobs.
#' @param connection a connection created by create_connection.
#' @param jobs_status a list returned by create_jobs, create_n_jobs or
#' update_jobs_status.
#' @param callback_function a function that is called for each result after
#' loading. This function must take one argument, which is the result of the
#' work performed. The value returned by this function is placed in the result
#' list.
#' @inherit create_n_jobs return
#' @details
#' When errors occur, execution can be stopped with the following messages:
#' * for unknown connections:
#'   * "Unknown protocol."
#' * for any connection:
#'   * "The number of tasks must be greater than 0."
#' This function can output the following warnings:
#' * for any connection:
#'   * Failed to download the result: "\code{<}error message\code{>}"
#'
#' @inherit create_n_jobs examples
update_jobs_status = function(connection, jobs_status, callback_function = NULL)
{
  for(k in seq_len(length(jobs_status$jobs_name))){
    mess = ""
    job_state = 0
    if (connection$type == "ssh"){
      # for ssh connections
      cmd_line = paste0("cd ",
                        connection$dir,
                        " && ./rboinc/bin/get_job_state.php ",
                        jobs_status$jobs_name[k])
      job_state = ssh_exec_wait(connection$connection,
                                cmd_line,
                                function(str){mess <<- rawToChar(str)})
    } else if (connection$type == "http"){
      # for http connections
      # Get user auth ID
      cook = cookies(connection$handle)
      auth = cook[cook["name"]=="auth", "value"]
      # Create request text
      get_job_xml =                     "<query_completed_job>"
      get_job_xml = paste0(get_job_xml,   "<authenticator>", auth, "</authenticator>")
      get_job_xml = paste0(get_job_xml,   "<job_name>", jobs_status$jobs_name[k], "</job_name>")
      get_job_xml = paste0(get_job_xml, "</query_completed_job>")
      response = content(POST(url = paste0(connection$url,"/submit_rpc_handler.php"),
                              body = list(request = get_job_xml),
                              handle = connection$handle))
      job_status = as_list(response)$query_completed_job$completed_job
      if(is.null(job_status$exit_status)){
        # job not complete or fails
        if(job_status$error_mask == 0){
          mess = "in_progress"
          job_state = 6
        } else {
          job_state = 5
          mess = paste0("error: ", job_status$error_mask)
        }
      }else{
        if (job_status$exit_status == 0){
          job_state = 0
          mess = paste0(connection$url, "/download/rboinc/", jobs_status$jobs_name[k])
        }
      }
    }else{
      stop ("Unknown protocol.")
    }
    if ((job_state == 0) && (jobs_status$jobs_code[k] != 0)){
      jobs_status$jobs_status[k] = "done"
      tmp = tryCatch(
        download_result(connection, mess, jobs_status$jobs_name[k], callback_function),
      error = function(mess){
        jobs_status$jobs_code = 7
        warning(paste0("Failed to download the result: \"", mess, "\""))
      })
      for(val in tmp){
        jobs_status$results[[val$pos]] = val$res
      }
    }else if (jobs_status$jobs_code[k] != 0){
      jobs_status$jobs_status[k] = mess
    }
    jobs_status$jobs_code[k] = job_state
  }
  jobs_status$status = "done"
  for(val in jobs_status$jobs_code){
    if((val == 6) && (jobs_status$status != "error")){
      jobs_status$status = "in_progress"
    } else if(val != 0){
      jobs_status$status = "error"
    }
  }
  return(jobs_status)
}
