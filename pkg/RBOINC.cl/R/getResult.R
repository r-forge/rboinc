# Original file name: "getResult.R"
# Created: 2021.02.08
# Last modified: 2023.09.04
# License: BSD-3-clause
# Written by: Astaf'ev Sergey <seryymail@mail.ru>
# This is a part of RBOINC R package.
# Copyright (c) 2021-2022 Karelian Research Centre of
# the RAS: Institute of Applied Mathematical Research
# All rights reserved

#' @importFrom ssh ssh_exec_wait
#' @importFrom ssh scp_download
#' @importFrom httr GET
#' @importFrom httr write_disk
#' @importFrom xml2 as_list
#' @importFrom xml2 xml_find_all

#' @export update_jobs_status

download_result = function(connection, job_name)
{
  tmp_dir = tempdir(TRUE)
  file_name = paste0(tmp_dir, "/", job_name)
  if(connection$type == "ssh"){
    scp_download(connection$connection,
                 paste0(connection$dir, "/download/rboinc/", job_name),
                 tmp_dir,
                 verbose = FALSE)
  }else if(connection$type == "http"){
    file = paste0(connection$url, "/download/rboinc/", job_name)
    donwload_res = GET(file, write_disk(file_name, overwrite=TRUE))
    # There is BOINC bug. The server reports on a successful job completion
    # earlier than copies the file to the result folder. Sometimes it
    # temporarily leads to error 404.
    if (donwload_res$status_code == 404){
      stop(paste0(file, " not found."))
    }
  }
  # fix for potential vulnerability
  tmpenv = new.env()
  load(file_name, tmpenv)
  unlink(file_name)
  return(tmpenv$result)
}

finalize_result = function(connection, jobs_status, k, callback_function)
{
  error_flag = FALSE
  tmp = tryCatch(
    download_result(connection, jobs_status$jobs_name[k]),
    error = function(mess){
      error_flag <<- TRUE
      warning(paste0("Failed to download result: \"", mess, "\""))
    })
  if(error_flag){
    jobs_status$jobs_status[k] = "tmp_error"
    return(jobs_status)
  } else{
    jobs_status$jobs_status[k] = "done"
  }
  # return raw or processed result:
  if(is.null(callback_function)){
    for(val in tmp){
      jobs_status$results[[val$pos]] = val$res
    }
  } else{
    for(val in tmp){
      jobs_status$results[[val$pos]] = callback_function(val$res)
    }
  }
  return(jobs_status)
}

update_jobs_status_ssh = function(connection, jobs_status, callback_function)
{
  error_flag = FALSE
  warning_flag = FALSE
  done_flag = TRUE
  for(k in seq_len(length(jobs_status$jobs_name))){
    if(jobs_status$jobs_status[k] == "done"){
      next
    }
    cmd_line = paste0("cd ", connection$dir,
                      " && ./rboinc/bin/get_job_state.php ",
                      jobs_status$jobs_name[k])
    mess = ""
    code = ssh_exec_wait(connection$connection, cmd_line,
                         function(str){mess <<- rawToChar(str)})
    # code can be:
    # 0 - Done
    # 3 - Result file not found
    # 4 - Job not exist
    # 5 - BOINC error(with error code)
    # 6 - Job in processing
    if(code != 0){
      done_flag = FALSE
      if(code >= 4){
        jobs_status$jobs_status[k] = mess
        if(code <= 5){
          error_flag = TRUE
        }
      } else if(code == 3){
        # Result file not found
        warning(paste0("Failed to download result: \"", mess, "\""))
        jobs_status$jobs_status[k] = "tmp_error"
        warning_flag = TRUE
      }
    } else if(code == 0){
      #done
      jobs_status = finalize_result(connection, jobs_status, k, callback_function)
      if(jobs_status$jobs_status[k] == "tmp_error"){
        warning_flag = TRUE
      }
    }
  }
  if(error_flag){
    jobs_status$status = "error"
  }else if(warning_flag){
    jobs_status$status = "warning"
  }else if(done_flag){
    jobs_status$status = "done"
  }else{
    jobs_status$status = "in_progress"
  }
  return(jobs_status)
}

update_jobs_status_http = function(connection, jobs_status, callback_function)
{
  error_flag = FALSE
  warning_flag = FALSE
  done_flag = TRUE
  response = send_http_message_to_server(connection, "query_batch",
                                         list(batch_id = jobs_status$batch_id,
                                              get_job_details = 1))
  is_jobs_id = TRUE
  if(is.null(jobs_status$jobs_id)){
    is_jobs_id = FALSE
    jobs_status$jobs_id = rep(0, length(jobs_status$jobs_name))
  }
  # For all jobs in batch:
  for(val in xml_find_all(response, ".//job")){
    #browser()
    job = as_list(val)
    pos = 0
    if(is_jobs_id){# Find position by id
      pos = which.max(as.numeric(job$id[[1]]) == jobs_status$jobs_id)
    } else{#Find position by name
      pos = which.max(job$name[[1]] == jobs_status$jobs_name)
      jobs_status$jobs_id[pos] = as.numeric(job$id[[1]])
    }
    if(jobs_status$jobs_status[pos] == "done"){
      next
    }
    # Copy status of job
    jobs_status$jobs_status[pos] = job$status[[1]]
    if(job$status[[1]] == "error"){
      error_flag = TRUE
      # Copy error code if exists
      if(!is.null(job$exit_status[[1]])){
        jobs_status$jobs_status[pos] = paste0(job$status[[1]], ": ", job$exit_status[[1]])
      } else{
        jobs_status$jobs_status[pos] = job$status[[1]]
      }
    } else if(job$status[[1]] == "done"){
      # Try to download result
      jobs_status = finalize_result(connection, jobs_status, pos, callback_function)
      if(jobs_status$jobs_status[pos] == "tmp_error"){
        warning_flag = TRUE
        done_flag = FALSE
      }
    } else {
      done_flag = FALSE
    }
  }
  if(error_flag){
    jobs_status$status = "error"
  }else if(warning_flag){
    jobs_status$status = "warning"
  }else if(done_flag){
    jobs_status$status = "done"
  }else{
    jobs_status$status = "in_progress"
  }
  return(jobs_status)
}

#' @title update_jobs_status
#' @description Update status for jobs and get result for complete jobs.
#' @param connection a connection created by
#' \link[=create_connection]{create_connection}
#' @param jobs_status a list returned by
#' \link[=create_jobs]{create_jobs} or update_jobs_status. This is reference
#' like in C++ language.
#' @param callback_function a function with prototype
#' \code{function(result_element)} that is called for each result after loading.
#' The value returned by this function is placed in the result list.
#' @inherit create_jobs return
#' @details
#' This function communicates with the boinc server and gets the state for each
#' job. If the job has already been completed, and its result has been
#' downloaded and processed, then it is skipped. After the last result is
#' downloaded, the jobs data is deleted from the server, and status field in the
#' return value is set to "done".
#'
#' ## Errors and warnings
#' When errors occur, execution can be stopped with the following messages:
#' * for unknown connections:
#'   * "Unknown protocol."
#' * for any connection:
#'   * "All jobs have already been canceled."
#'   * "All results have already been received."
#'
#' This function can output the following warnings:
#' * for any connection:
#'   * Failed to download the result: "\code{<}error message\code{>}"
#'
#' @inherit create_jobs examples
update_jobs_status = function(connection, jobs_status, callback_function = NULL)
{
  if(jobs_status$status == "done"){
    stop("All results have already been received.")
  } else if(jobs_status$status == "aborted"){
    stop("All jobs have already been canceled.")
  }
  orig_name = deparse(substitute(jobs_status))
  if(connection$type == "ssh"){
    jobs_status = update_jobs_status_ssh(connection, jobs_status, callback_function)
    # File deletion from server:
    if(jobs_status$status == "done"){
      # Unlike the http version, this is a crutch. I did not find an api for
      # deleting files of a specific job, only for deleting the entire batch
      # of jobs. So I just cancel the job when I no longer need it. TODO:
      # Rewrite create_job_ssh so that it creates a batch of jobs rather than
      # individual jobs.
      for(val in jobs_status$jobs_name){
        ssh_exec_wait(connection$connection,
                      paste0("cd ", connection$dir, " && " ,
                             "./bin/cancel_jobs --name ", val))
      }
    }
  }else if(connection$type == "http"){
    jobs_status = update_jobs_status_http(connection, jobs_status, callback_function)
    # File deletion from server:
    if(jobs_status$status == "done"){
      send_http_message_to_server(connection, "retire_batch",
                                  list(batch_id = jobs_status$batch_id))
    }
  }else{
    stop ("Unknown protocol.")
  }
  tmp = parent.frame()
  eval(parse(text = paste0("tmp$", orig_name, " = jobs_status")))
  return(jobs_status)
}
