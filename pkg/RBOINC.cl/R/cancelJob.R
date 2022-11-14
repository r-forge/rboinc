# Original file name: "cancelJob.R"
# Created: 2021.10.20
# Last modified: 2022.11.14
# License: BSD-3-clause
# Written by: Astaf'ev Sergey <seryymail@mail.ru>
# This is a part of RBOINC R package.
# Copyright (c) 2021-2022 Karelian Research Centre of
# the RAS: Institute of Applied Mathematical Research
# All rights reserved

#' @importFrom ssh ssh_exec_wait

#' @export cancel_jobs

#' @title cancel_jobs
#' @description Cancel running jobs.
#' @param connection a connection created by
#' \link[=create_connection]{create_connection}
#' @param jobs_status a list returned by \link[=create_jobs]{create_jobs} or
#' \link[=update_jobs_status]{update_jobs_status}. This is reference like in C++
#' language.
#' @inherit create_jobs return
#' @details
#' This function cancels the specified jobs on the server. Status field in the
#' return value is set to "aborted".
#'
#'## Errors and warnings
#' When errors occur, execution can be stopped with the following messages:
#' * for unknown connections:
#'   * "Unknown protocol."
#' * for http/https connections:
#'   * "BOINC server error: "\code{<}error message\code{>}""
#' * for any connection:
#'   * "All results have already been received."
#'   * "All jobs have already been canceled."
#' @examples
#' \dontrun{
#'
#' # Function for data processing:
#' fun = function(val)
#' {
#'    ...
#' }
#'
#' # Data for processing:
#' data = list(...)
#'
#' # Connection to the BOINC server:
#' con = create_connection(...)
#'
#' # Send jobs to BOINC server:
#' jobs = create_jobs(con, fun, data)
#'
#' # Cancel jobs:
#' jobs = cancel_jobs(con, jobs)
#'
#' # Stopped with error:
#' jobs = update_jobs_status(con, jobs)
#'
#' # Release resources:
#' close_connection(con)
#' }
cancel_jobs = function(connection, jobs_status)
{
  if(jobs_status$status == "done"){
    stop("All results have already been received.")
  } else if(jobs_status$status == "aborted"){
    stop("All jobs have already been canceled.")
  }
  orig_name = deparse(substitute(jobs_status))
  if(connection$type == "ssh"){
    for(val in jobs_status$jobs_name){
      ssh_exec_wait(connection$connection,
                    paste0("cd ", connection$dir, " && " ,
                           "./bin/cancel_jobs --name ", val))
    }
  }else if(connection$type == "http"){
    response = send_http_message_to_server(connection, "abort_batch",
                                list(batch_id = jobs_status$batch_id))
    tmp = as_list(response)$abort_batch
    if (exists("error", envir = as.environment(tmp))){
      stop("BOINC server error: \"", tmp$error$error_msg[[1]], "\".")
    }
    response = send_http_message_to_server(connection, "retire_batch",
                                list(batch_id = jobs_status$batch_id))
    tmp = as_list(response)$retire_batch
    if (exists("error", envir = as.environment(tmp))){
      stop("BOINC server error: \"", tmp$error$error_msg[[1]], "\".")
    }
  }else{
    stop("Unknown protocol.")
  }
  jobs_status$status = "aborted"
  tmp = parent.frame()
  eval(parse(text = paste0("tmp$", orig_name, " = jobs_status")))
  return(jobs_status)
}

