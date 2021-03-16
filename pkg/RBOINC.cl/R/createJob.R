# Original file name: "createJob.R"
# Created: 2021.02.04
# Last modified: 2021.03.16
# License: Comming soon
# Written by: Astaf'ev Sergey <seryymail@mail.ru>
# This is a part of RBOINC R package.

#' @importFrom ssh ssh_exec_wait
#' @importFrom httr POST
#' @importFrom httr upload_file
#' @importFrom httr content
#' @importFrom httr cookies
#' @importFrom xml2 as_list
#' @importFrom xml2 xml_find_all

#' @export create_jobs

create_job_xml = function(auth, files)
{
  request =                 "<submit_batch>\n"
  request = paste0(request, "  <authenticator>", auth,"</authenticator>\n")
  request = paste0(request, "  <batch>\n")
  request = paste0(request, "    <app_name>rboinc</app_name>\n")
  request = paste0(request, "    <batch_name>", format(Sys.time(), "rboinc_%s"), ".",ceiling(runif(1, 0, 10000000)),"</batch_name>\n")
  request = paste0(request, "    <output_template_filename>rboinc_result.xml</output_template_filename>\n")
  request = paste0(request, "    <input_template_filename>rboinc_wu.xml</input_template_filename>\n")
  for(val in files$data){
    request = paste0(request, "    <job>\n")
    request = paste0(request, "      <input_file>\n")
    request = paste0(request, "        <mode>local_staged</mode>\n")
    request = paste0(request, "        <source>", files$common,"</source>\n")
    request = paste0(request, "      </input_file>\n")
    request = paste0(request, "      <input_file>\n")
    request = paste0(request, "        <mode>local_staged</mode>\n")
    request = paste0(request, "        <source>", val,"</source>\n")
    request = paste0(request, "      </input_file>\n")
    request = paste0(request, "    </job>\n")
  }
  request = paste0(request, "  </batch>\n")
  request = paste0(request, "</submit_batch>")

}

register_jobs = function(connection, files)
{
  # job names
  jobs = character(length(files$data))
  # get unique job name
  job_name = ""
  ssh_exec_wait(connection$connection, paste0(connection$dir, "/rboinc/bin/get_job_name.sh"), function(str){job_name <<- rawToChar(str)})
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
#'   * "in_progress" - BOINC is serves jobs.
#'   * "done" - computations complete, result downloaded.
#'   * "error" - an error occurred where jobs processing.
#'   * "queued" - job in queue (only for http/https connections).
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
#' #con = create_connection("ssh://boinc-server.local", dir = "~/projects/myproject", username = "boincadm", password = "0000") # ssh
#' #con = create_connection("http://boinc-server.local", dir = "myproject", username = "submitter@example.com", password = "000000")# http
#' con
#' # send jobs:
#' jobs = create_jobs(con, fun, data, init, glob_vars)
#' jobs
#' # Get jobs status. Run this until status not equal "done":
#' jobs = update_jobs_status(con, jobs)
#' jobs
#' # Close connection:
#' close_connection(con)
create_jobs = function(connection, work_func, data, init_func = NULL, global_vars = NULL, packages = c(), files = c())
{
  if(connection$type == "ssh"){
    ar = make_archive(work_func, deparse(substitute(work_func)), data, init_func, global_vars, packages, files)
    files = stage_files(con, ar, length(data))
    jobs = register_jobs(connection, files)
    ret = list(jobs_name = jobs, results = vector("list", length = length(jobs)), jobs_status = character(length(files$data)), jobs_code = rep(-1, length(files$data)), status = "initialization")
    return(ret)
  } else if (connection$type == "http"){
    ar = make_archive(work_func, deparse(substitute(work_func)), data, init_func, global_vars, packages, files)
    # Send archive to server
    response = POST(url = paste0(connection$url, "/rboinc_upload_archive.php"), body = list(archive = upload_file(ar)), config = content_type("multipart/form-data"), handle = connection$handle)
    files = as_list(content(response))
    # Get user auth ID
    cook = cookies(connection$handle)
    auth = cook[cook["name"]=="auth", "value"]
    # Registry jobs
    request = create_job_xml(auth, files$staged_files)
    batch = content(POST(url = paste0(connection$url,"/submit_rpc_handler.php"), body = list(request = request), handle = connection$handle))
    # Get jobs statuses
    query_xml =                   "<query_batch>\n"
    query_xml = paste0(query_xml, "  <authenticator>", auth, "</authenticator>\n")
    query_xml = paste0(query_xml, "  <batch_id>", as_list(batch)$submit_batch$batch_id[[1]], "</batch_id>\n")
    query_xml = paste0(query_xml, "  <get_job_details>1</get_job_details>\n")
    query_xml = paste0(query_xml, "</query_batch>")
    jobs = content(POST(url = paste0(connection$url,"/submit_rpc_handler.php"), body = list(request = query_xml), handle = connection$handle))
    jobs = xml_find_all(jobs, "job")
    # make returned list
    jobs_name = character(length(jobs))
    jobs_status = character(length(jobs))
    for(k in 1:length(jobs)){
      val = as_list(jobs[k])[[1]]
      jobs_name[k] = val$name[[1]]
      jobs_status[k] = val$status[[1]]
    }
    ret = list(jobs_name = jobs_name, results = vector("list", length = length(jobs)), jobs_status = jobs_status, jobs_code = rep(-1, length(jobs)), status = "initialization")
    return(ret)
  } else {
    return (NULL)
  }
}
