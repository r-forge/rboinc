# Original file name: "createJob.R"
# Created: 2021.02.04
# Last modified: 2022.01.31
# License: BSD-3-clause
# Written by: Astaf'ev Sergey <seryymail@mail.ru>
# This is a part of RBOINC R package.
# Copyright (c) 2021-2022 Karelian Research Centre of
# the RAS: Institute of Applied Mathematical Research
# All rights reserved

#' @importFrom ssh ssh_exec_wait
#' @importFrom httr POST
#' @importFrom httr upload_file
#' @importFrom httr content
#' @importFrom httr cookies
#' @importFrom httr set_cookies
#' @importFrom xml2 as_list
#' @importFrom xml2 xml_find_all
#' @importFrom stats runif
#' @importFrom stats setNames

#' @export create_jobs

obtain_cookies = function(connection)
{
  cook = cookies(connection$handle)
  ret = setNames(as.character(cook$value), as.character(cook$name))
  return(ret)
}

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
                       handle = connection$handle,
                       set_cookies(obtain_cookies(connection))))
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
                      handle = connection$handle,
                      set_cookies(obtain_cookies(connection))))
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
  if(is.null(data)){
    data = rep(0, n)
  }
  l = length(data)
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
  return(list(data = ret, max_len = maxLen))
}

#' @title create_jobs
#' @description Creates a jobs on BOINC server.
#' @param connection a connection returned by
#' \link[=create_connection]{create_connection}.
#' @param work_func data processing function with prototype
#' \code{function(data_element)} if 'data' is specified or \code{function()} if
#' 'n' is specified. This function runs for each element in data. This function
#' can be recursive.
#' @param data data for processing.  Must be a numerable list or vector.
#' @param n a number of jobs. This parameter must be less than or equal to the
#' length of the data. If not specified, then the number of jobs will be equal
#' to the length of the data.
#' @param init_func initialization function with prototype \code{function()}.
#' This function runs once at the start of a job before the job is split into
#' separate threads. This function can not to be recursive.
#' @param global_vars a list in the format
#' \code{<}variable name\code{>}=\code{<}value\code{>}.
#' @param packages a string vector with imported packages names.
#' @param files a string vector with the files names that should be available
#' for jobs.
#' @param install_func installation function with prototype
#' \code{function(packages)}, where packages is a vector with package names
#' which cannot be installed from repositories. This function can not to be
#' recursive.
#' @return a list with current states of jobs. This list contains the following
#' fields:
#' * batch_id - ID of the batch that includes the jobs;
#' * jobs_name - a name of jobs on BOINC server;
#' * results - computation results (NULL if computation is still incomplete);
#' The length of this list is equal to the length of the data;
#' * jobs_status - human-readable status for each job;
#' * status - computation status, may be:
#'   * "initialization" - jobs have been submitted to the server, but their
#'   status was not requested by update_jobs_status;
#'   * "in_progress" - BOINC serves jobs;
#'   * "done" - computations are complete, the results were downloaded;
#'   * "warning" a recoverable error occurred during the job processing;
#'   * "error" - a serious error occurred during the job processing;
#'   * "aborted" - processing was canceled using the
#'   \link[=cancel_jobs]{cancel_jobs} function.
#' @details
#' This function automatically breaks the data into n parts and creates n jobs.
#' The number of jobs must be greater than zero.
#'
#' Parameter init_func is necessary for additional initialization, for example,
#' for compiling C++ functions from sources transferred through files parameter.
#' It runs for all computation nodes but not for main node.
#'
#' The job is performed as follows:
#' 1. The necessary \code{packages} are first loaded/installed;
#' 1. If some packages were not installed, the
#' \code{RBOINC_additional_inst_func} function is called which is renamed
#' \code{install_func}.
#' 1. The \code{RBOINC_work_func} and \code{RBOINC_init_func} functions are
#' loaded which are renamed \code{work_func} and \code{init_func};
#' 1. The \code{RBOINC_data} object is loaded which is renamed part of
#' \code{data};
#' 1. The working folder changes to the one where the \code{files} were copied;
#' 1. According to the number of detected cores, a cluster is created with the
#' name "RBOINC_cluster"
#' 1. The \link[doParallel:registerDoParallel]{registerDoParallel(RBOINC_cluster)}
#' function is called;
#' 1. The original name of the \code{RBOINC_work_func} function is restored;
#' 1. \code{global_vars} are copied to the global environment;
#' 1. The \code{RBOINC_init_func()} function is called;
#' 1. The job is divided into sub-tasks and is performed in parallel.
#' 1. Execution results are collected together and sent to the BOINC server.
#'
#' ## Restrictions
#' Don't create or use objects that begin with the prefix \code{RBOINC_}.
#'
#' Don't rely on any packages to be loaded automatically. Specify the necessary
#' packages explicitly through the \code{packages} parameter.
#'
#' Don't pass in global_vars objects that cannot be saved, such as functions
#' compiled from C++ code.
#'
#' Packages passed in \code{packages} will be installed from the repositories
#' specified in your R environment. Additionally, https://cloud.r-project.org is
#' added to the list of repositories. Only CRAN-like repositories are supported.
#'
#' Packages that require compilation may depend on header files and libraries
#' that are not in the VM. Such packages cannot be installed in the standard
#' way.
#'
#' init_func is only called on processing nodes created by makeCluster. if
#' nothing is being processed in the master node, it will not be called in
#' master node.
#'
#' install_func is always called. As a parameter, it is passed a vector of
#' strings with the names of packages for which the installation failed a
#' parameter equal to the vector with names of packages installation of that is
#' failed. If you need to use functions from packages passed to \code{packages},
#' then refer to them with a colon.
#'
#' ## Errors and warnings
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
#'   * "You must specify 'data' or 'n'."
#'
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
#' # Get status for jobs:
#' jobs = update_jobs_status(con, jobs)
#'
#' # Release resources:
#' close_connection(con)
#' }
create_jobs = function(connection,
                       work_func,
                       data = NULL,
                       n = NULL,
                       init_func = NULL,
                       global_vars = NULL,
                       packages = c(),
                       files = c(),
                       install_func = NULL)
{
  is_NULL_data = FALSE
  if(is.null(data) && is.null(n)){
    stop("You must specify 'data' or 'n'.")
  } else if(is.null(n)){
    n = length(data)
  } else if(n < 1){
    stop("The number of tasks must be greater than 0.")
  } else if(is.null(data)){
    is_NULL_data = TRUE
  } else if(n > length(data)){
    stop("The number of tasks must be less or equal than length of data.")
  }
  if((connection$type != "ssh") && (connection$type != "http")){
    stop ("Unknown protocol.")
  }
  if(is_NULL_data){
    result_count = n
  }else {
    result_count = length(data)
  }
  lst = split_list(data, n)
  ar = make_archive(work_func,
                    deparse(substitute(work_func)),
                    lst,
                    init_func,
                    global_vars,
                    packages,
                    files,
                    install_func,
                    is_NULL_data)
  if(connection$type == "ssh"){
    # Send archive to server
    files = stage_files_ssh(connection, ar, n)
    # Get jobs names
    jobs = register_jobs_ssh(connection, files)
  } else if (connection$type == "http"){
    # Send archive to server
    response = POST(url = paste0(connection$url, "/rboinc_upload_archive.php"),
                    body = list(archive = upload_file(ar)),
                    config = content_type("multipart/form-data"),
                    handle = connection$handle,
                    set_cookies(obtain_cookies(connection)))
    if(response$status_code == 403){
      stop("You can not create jobs.")
    }
    xml_data = as_list(content(response))
    # Get jobs names
    jobs = register_jobs_http(connection, xml_data)
  }
  ret = list(batch_id = jobs$batch_id,
             jobs_name = jobs$jobs_name,
             results = vector("list", length = result_count),
             jobs_status = rep("initialization", length(jobs$jobs_name)),
             status = "initialization")
  return(ret)
}
