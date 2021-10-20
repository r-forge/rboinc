# Original file name: "cancelJob.R"
# Created: 2021.10.20
# Last modified: 2021.10.20
# License: BSD-3-clause
# Written by: Astaf'ev Sergey <seryymail@mail.ru>
# This is a part of RBOINC R package.
# Copyright (c) 2021 Karelian Research Centre of the RAS:
# Institute of Applied Mathematical Research
# All rights reserved

#' @importFrom ssh ssh_exec_wait

#' @export cancel_jobs

#' @title cancel_jobs
#' @description Cancel running jobs.
#' @param connection a connection created by create_connection.
#' @param jobs_status a list returned by create_jobs or update_jobs_status.
#' @inherit create_jobs return
#' @details
#' When errors occur, execution can be stopped with the following messages:
#' * for unknown connections:
#'   * "Unknown protocol."
#' * for any connection:
#'   * "All results have already been received."
cancel_jobs = function(connection, jobs_status)
{
  if(jobs_status$status == "done"){
    stop("All results have already been received.")
  } else if(jobs_status$status == "aborted"){
    stop("All jobs have already been canceled.")
  }
  if(connection$type == "ssh"){
    for(val in jobs_status$jobs_name){
      ssh_exec_wait(connection$connection,
                    paste0("cd ", connection$dir, " && " ,
                           "./bin/cancel_jobs --name ", val))
    }
  }else if(connection$type == "http"){
    send_http_message_to_server(connection, "abort_batch",
                                list(batch_id = jobs_status$batch_id))
    send_http_message_to_server(connection, "retire_batch",
                                list(batch_id = jobs_status$batch_id))
  }else{
    stop("Unknown protocol.")
  }
  jobs_status$status = "aborted"
  return(jobs_status)
}
