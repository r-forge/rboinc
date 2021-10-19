# Original file name: "createJob.R"
# Created: 2021.02.04
# Last modified: 2021.10.19
# License: BSD-3-clause
# Written by: Astaf'ev Sergey <seryymail@mail.ru>
# This is a part of RBOINC R package.
# Copyright (c) 2021 Karelian Research Centre of the RAS:
# Institute of Applied Mathematical Research
# All rights reserved

#' @importFrom ssh ssh_exec_wait
#' @importFrom httr POST
#' @importFrom httr upload_file
#' @importFrom httr content
#' @importFrom httr cookies
#' @importFrom xml2 as_list
#' @importFrom xml2 xml_find_all
#' @importFrom stats runif

#' @export create_jobs

create_job_xml = function(auth, files)
{
  request = paste0(
    "<submit_batch>",
      "<authenticator>", auth,"</authenticator>",
      "<batch>",
        "<app_name>rboinc</app_name>",
        "<batch_name>", files$batch_name,"</batch_name>",
        "<output_template_filename>rboinc_result.xml</output_template_filename>",
        "<input_template_filename>rboinc_wu.xml</input_template_filename>")
  k = 1
  for(val in files$data){
    request = paste0(request,
        "<job>",
          "<name>", files$batch_name, "_", k,"</name>",
          "<input_file>",
            "<mode>local_staged</mode>",
            "<source>", files$common,"</source>",
          "</input_file>",
          "<input_file>",
            "<mode>local_staged</mode>",
            "<source>", val,"</source>",
          "</input_file>",
        "</job>")
    k = k + 1
  }
  request = paste0(request,
      "</batch>",
    "</submit_batch>")
  return(request)
}

register_jobs_http = function(connection, xml_data)
{
  # Get user auth ID
  cook = cookies(connection$handle)
  auth = cook[cook["name"]=="auth", "value"]
  # Registry jobs
  request = create_job_xml(auth, xml_data$staged_files)
  batch = content(POST(url = paste0(connection$url,"/submit_rpc_handler.php"),
                       body = list(request = request),
                       handle = connection$handle))
  # test for user privilegies
  tmp = as_list(batch)$submit_batch
  if (exists("error", envir = as.environment(tmp))){
    stop("BOINC server error: \"", tmp$error$error_msg[[1]], "\".")
  }
  # Get jobs statuses
  query_xml = paste0(
    "<query_batch>",
      "<authenticator>", auth, "</authenticator>",
      "<batch_id>", as_list(batch)$submit_batch$batch_id[[1]], "</batch_id>",
      "<get_job_details>1</get_job_details>",
    "</query_batch>")
  jobs = content(POST(url = paste0(connection$url,"/submit_rpc_handler.php"),
                      body = list(request = query_xml),
                      handle = connection$handle))
  jobs = xml_find_all(jobs, "job")
  # make returned list
  jobs_name = character(length(jobs))
  #jobs_status = character(length(jobs))
  for(k in seq_len(length(jobs))){
    val = as_list(jobs[k])[[1]]
    jobs_name[k] = val$name[[1]]
    #jobs_status[k] = val$status[[1]]
  }
  return(list(jobs_name = jobs_name, batch_id = as_list(batch)$submit_batch$batch_id[[1]]))
}


register_jobs_ssh = function(connection, files)
{
  # job names
  jobs = character(length(files$data))
  # get unique job name
  job_name = ""
  ssh_exec_wait(connection$connection,
                paste0(connection$dir, "/rboinc/bin/get_job_name.sh"),
                function(str){job_name <<- rawToChar(str)})
  # Create string for job registration
  jobs_text = ""
  for(k in seq_len(length(files$data))){
    jobs[k] = paste0(job_name, "_", k)
    jobs_text = paste0(jobs_text, "--wu_name ", jobs[k], " ", files$common, " ", files$data[[k]], "\\n")
  }
  # Register jobs
  cmd_str = paste0( "cd ", connection$dir, " && ")
  cmd_str = paste0(cmd_str, "./bin/create_work --appname rboinc --wu_template ./templates/rboinc_wu.xml ",
                   "--result_template ./templates/rboinc_result.xml --stdin ")
  cmd_str = paste0(cmd_str, "<<<`echo -en '", jobs_text, "'`")
  ssh_exec_wait(connection$connection, cmd_str)
  return(list(jobs_name = jobs, batch_id = NULL))
}

split_list = function(data, n)
{
  l = length(data)
  n = ifelse(n > l, l, n)
  ret = vector("list", n)
  maxLen = ceiling(l/n)
  minLen = floor(l/n)
  maxCount = ifelse(minLen != maxLen , (minLen*n-l)/(minLen - maxLen), n)
  minCount = n - maxCount
  k = 1
  while(k <= maxCount){
    ret[[k]] = vector("list", maxLen)
    k = k + 1
  }
  while(k <= (maxCount + minCount)){
    ret[[k]] = vector("list", minLen)
    k = k + 1
  }
  i = 1
  j = 1
  k = 1
  for (value in data){
    ret[[i]][[j]] = list(val = value, pos = k)
    k = k + 1
    j = j + 1
    if(j > length(ret[[i]])){
      j = 1
      i = i + 1
    }
  }
  return(ret)
}

#' @title create_jobs
#' @description This function automatically breaks the data into n parts and
#' creates n jobs.
#' @param connection a connection created by create_connection.
#' @param work_func data processing function. This function runs for each
#' element in data. This function can be recursive.
#' @param data data for processing.  Must be a numerable list or vector.
#' @param n a number of jobs. This parameter must be less than or equal to the
#' length of the data. If not specified, then the number of jobs will be equal
#' to the length of the data.
#' @param init_func initialization function. This function runs once at the
#' start of a job before the job is split into separate threads. Necessary for
#' additional initialization, for example, for compiling C++ functions from
#' sources transferred through files parameter. This function can not to be
#' recursive.
#' @param global_vars a list in the format
#' \code{<}variable name\code{>}=\code{<}value\code{>}.
#' @param packages a string vector with imported packages names.
#' @param files a string vector with the files names that should be available
#' for jobs.
#' @return a list with current states of jobs. This list contains the following
#' fields:
#' * jobs_name - a name of job on BOINC server;
#' * results - computation results (NULL if computation is still incomplete).
#' The length of this list is equal to the length of the data;
#' * jobs_status - jobs human-readable status for each job;
#' * jobs_code - jobs status code, don't use this field;
#' * status - computation status, may be:
#'   * "initialization" - jobs have been submitted to the server, but their
#'   status was not requested by update_jobs_status.
#'   * "in_progress" - BOINC serves jobs.
#'   * "done" - computations are complete, the result was downloaded.
#'   * "error" - an error occurred during the job processing.
#'   * "queued" - job in the queue (only for http/https connections).
#' @details
#' When errors occur, execution can be stopped with the following messages:
#' * for http connections:
#'   * "You can not create jobs."
#'   * "BOINC server error: "\code{<}server message\code{>}"."
#' * for unknown connections:
#'   * "Unknown protocol."
#' * for any connection:
#'   * "The number of tasks must be greater than 0."
#'   * "The number of tasks must be less than or equal to the length of the data."
#'   * "Archive making error: \code{<}error message\code{>}"
#'
#' @examples
#' \dontrun{
#' # import library
#' library(RBOINC.cl)
#' # function for data processing
#' fun = function(val)
#' {
#'   return(val * a + b)
#' }
#' # global variables
#' glob_vars = list(a = 3, b = 2)
#' # Initialization function. This function runs on each node for one times.
#' init = function()
#' {
#'   return(NULL)
#' }
#' # data for processing
#' data = list(matrix(rexp(15), 3,5), matrix(rexp(15), 3,5))
#'
#' #callback function
#' print_func = function(val)
#' {
#'   print(val)
#'   # May be any value
#'   return(val)
#'   #return(NULL)
#' }
#'
#' # Test jobs before sending
#' jobs_t = test_jobs(fun, data, init_func = init, global_vars = glob_vars, callback_function = print_func)
#' jobs_t
#' jobs_t = test_jobs(fun, data, 1, init, glob_vars, callback_function = print_func)
#' jobs_t
#'
#' # Create connection:
#' #con = create_connection("ssh://boinc.local", "~/projects/myproject", "boincadm", "0000") # ssh
#' #con = create_connection("http://boinc.local", "myproject", "submitter@example.com","000000")# http
#' con
#' # send jobs:
#' #jobs = create_jobs(con, fun, data, init_func = init, global_vars = glob_vars)
#' #jobs = create_jobs(con, fun, data, 1, init, glob_vars)
#' jobs
#' # Get jobs status. Run this until status not equal "done":
#' jobs = update_jobs_status(con, jobs)
#' jobs
#' # Close connection:
#' close_connection(con)
#' }
create_jobs = function(connection,
                         work_func,
                         data,
                         n = NULL,
                         init_func = NULL,
                         global_vars = NULL,
                         packages = c(),
                         files = c())
{
  if(is.null(n)){
    n = length(data)
  } else if(n < 1){
    stop("The number of tasks must be greater than 0.")
  } else if(n > length(data)){
    stop("The number of tasks must be less or equal than length of data.")
  }
  if((connection$type != "ssh") && (connection$type != "http")){
    stop ("Unknown protocol.")
  }
  result_count = length(data)
  lst = split_list(data, n)
  ar = make_archive(work_func,
                    deparse(substitute(work_func)),
                    lst,
                    init_func,
                    global_vars,
                    packages,
                    files)
  status = ""
  if(connection$type == "ssh"){
    # Send archive to server
    files = stage_files_ssh(connection, ar, n)
    # Get jobs names
    jobs = register_jobs_ssh(connection, files)
    status = "initialization"
  } else if (connection$type == "http"){
    # Send archive to server
    response = POST(url = paste0(connection$url, "/rboinc_upload_archive.php"),
                    body = list(archive = upload_file(ar)),
                    config = content_type("multipart/form-data"),
                    handle = connection$handle)
    if(response$status_code == 403){
      stop("You can not create jobs.")
    }
    xml_data = as_list(content(response))
    # Get jobs names
    jobs = register_jobs_http(connection, xml_data)
    status =  character(length(xml_data$data))
  }
  ret = list(batch_id = jobs$batch_id,
             jobs_name = jobs$jobs_name,
             results = vector("list", length = result_count),
             jobs_status = status,
             jobs_code = rep(-1, length(jobs)),
             status = "initialization")
  return(ret)
}
