# Original file name: "createJob.R"
# Created: 2021.02.04
# Last modified: 2021.02.09
# License: Comming soon
# Written by: Astaf'ev Sergey <seryymail@mail.ru>
# This is a part of RBOINC R package.

#' @importFrom ssh ssh_exec_wait

#' @export create_jobs

register_jobs = function(connection, files)
{
  # job names
  jobs = character(length(files$data))
  # get unique job name
  job_name = ""
  ssh_exec_wait(connection$connection, paste0(connection$dir, "/rboinc/bin/get_job_name.sh"), function(str){job_name <<- rawToChar(str[1:(length(str)-1)])})
  # Create file for job registration
  job_file = ""
  ssh_exec_wait(connection$connection, "date +\"%G_%m_%d_%I_%M_%S_%N\"", function(str){job_file <<- rawToChar(str[1:(length(str)-1)])})
  job_file = paste0("~/.rboinc_cache/", job_file)
  # Write file
  cmd_list = character(length(files$data))
  for(k in 1:length(files$data)){
    jobs[k] = paste0(job_name, "_", k)
    cmd_list[k] = paste0("echo --wu_name ", jobs[k], " ", files$common, " ", files$data[[k]], " >> ", job_file)
  }
  ssh_exec_wait(connection$connection, cmd_list)
  # Registre jobs
  ssh_exec_wait(connection$connection, paste0( "cd ", connection$dir, " && ./bin/create_work --appname rboinc --wu_template ./templates/rboinc_wu.xml --result_template ./templates/rboinc_result.xml --stdin <", job_file))
  ssh_exec_wait(connection$connection, paste0("rm ", job_file))
  return(jobs)
}

#' @title create_jobs
#' @description Send job to BOINC server for parallel processing.
#' @param connection a connection created by create_connection.
#' @param work_func data processing function.
#' @param data data for processing.  Must be a list!!!
#' @param init_func initialization function.
#' @param global_vars a list in the format <variable name>=<value>.
#' @param packages a string vector with imported packages names.
#' @param files a string vector with the filenames that should be available for jobs.
#' @return a list with current states of jobs. This list contains the following fields:
#' * jobs_name - a name of job on BOINC server;
#' * results - computation results (NULL if computation still not complete);
#' * jobs_status - jobs human-readable status for each job;
#' * jobs_code - jobs status code, don't use this field;
#' * status - computation status, may be:
#'   * "initialization" - jobs have been submitted to the server, but their status was not requested by update_jobs_status.
#'   * "computation" - BOINC is serves jobs.
#'   * "complete" - computations complete, result downloaded.
#'   * "error" - an error occurred where jobs processing.
#' @examples
#' # import library
#' library(RBOINC.cl)
#' # function for processing data
#' fun = function(val)
#' {
#'   return(val * a + b)
#' }
#' # global variables
#' glob_vars = list(a = 3)
#' # initialize function
#' init = function()
#' {
#'   b <<- 2
#' }
#' # data for processing
#' data = list(matrix(rexp(15), 3,5), matrix(rexp(15), 3,5))
#'
#' # Create connection:
#' con = create_connection("boincadm@boinc-server.local", dir = "~/projects/myproject", password = "0000")
#' con
#' # send jobs:
#' jobs = create_jobs(con, fun, data, init, glob_vars)
#' jobs
#' # Get jobs status. Run this until status not equal "complete":
#' jobs = update_jobs_status(con, jobs)
#' jobs
#' # Close connection:
#' close_connection(con)
create_jobs = function(connection, work_func, data, init_func = NULL, global_vars = NULL, packages = c(), files = c())
{
  ar = make_archive(work_func, data, init_func, global_vars, packages, files)
  files = stage_files(con, ar, length(data))
  jobs = register_jobs(connection, files)
  ret = list(jobs_name = jobs, results = vector("list", length = length(jobs)), jobs_status = character(length(files$data)), jobs_code = rep(-1, length(files$data)), status = "initialization")
  return(ret)
}
