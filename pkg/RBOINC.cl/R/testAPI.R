# Original file name: "testAPI.R"
# Created: 2021.03.19
# Last modified: 2022.11.11
# License: BSD-3-clause
# Written by: Astaf'ev Sergey <seryymail@mail.ru>
# This is a part of RBOINC R package.
# Copyright (c) 2021-2022 Karelian Research Centre of
# the RAS: Institute of Applied Mathematical Research
# All rights reserved

#' @importFrom R.utils printf
#' @importFrom utils tar
#' @importFrom utils untar

# The next lines was added only to add foreach to the list of dependencies.
# foreach is used by the generated script and therefore is required by the
# functions from the testAPI.R
#' @importFrom foreach foreach
#' @importFrom doParallel registerDoParallel
#' @importFrom parallel makeCluster
#' @importFrom parallel detectCores
#' @importFrom BiocManager install
#' @importFrom gtools getDependencies

#' @export test_jobs

#' @title test_jobs
#' @description performing jobs locally.
#' @inherit create_jobs params
#' @inherit update_jobs_status params
#' @return a list with states of jobs. This list contains the following fields:
#' * log - Rscript output;
#' * result - computation result.
#' @details
#' Like \link[=create_jobs]{create_jobs}, it creates a jobs for the BOINC server
#' but does not submit them. Instead, it runs all jobs locally and generates a
#' report at each step. This function is intended for debugging applications
#' that use RBOINC. Files created by this function are not deleted after its
#' completion.
#'
#'## Errors and warnings
#' When errors occur, execution can be stopped with the following messages:
#' * "Archive making error: \code{<}error message\code{>}"
#' * "You must specify 'data' or 'n'."
#' * "The number of tasks must be less or equal than length of data."
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
#' # Test jobs locally:
#' res = test_jobs(fun, data)
#'
#' }
test_jobs = function(work_func,
                       data = NULL,
                       n = NULL,
                       init_func = NULL,
                       global_vars = NULL,
                       packages = c(),
                       files = c(),
                       callback_function = NULL,
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
  old_wd = getwd()
  on.exit(setwd(old_wd), TRUE)
  printf("Testing archive making...\t")
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
  if(is.null(ar)){
    printf("Error\n")
    return(NULL)
  } else{
    printf("OK: %s\n",ar)
  }
  printf("Creating tmp dir for test...\t")
  tmpdir = tempfile()
  dir.create(tmpdir, FALSE)
  if(dir.exists(tmpdir)){
    printf("OK: %s\n",tmpdir)
  }else {
    printf("Error\n")
    return(NULL)
  }


  printf("Testing archive unpacking...\t")
  if(untar(ar, exdir = tmpdir, tar = "internal") == 0){
    printf("OK: founded files:\n")
    for(val in list.files(tmpdir, full.names = TRUE, recursive = TRUE)){
      printf("\t%s\n", val)
    }
  } else {
    printf("Error\n")
    return(NULL)
  }
  printf("Searching jobs...\t")
  jobs = list.files(paste0(tmpdir, "/data"))
  if(length(jobs) != 0){
    printf("OK: %i\n", length(jobs))
  }else{
    printf("Error\n")
    return(NULL)
  }
  result = vector("list", length(data))
  job_dir = tempfile()
  dir.create(job_dir, FALSE)
  for(val in jobs){
    t = paste0(job_dir, "/", basename(val))
    printf("Running job %s in %s ", val, t)
    dir.create(t, FALSE)
    file.copy(paste0(tmpdir, "/data/", val), paste0(t, "/data.rda"))
    untar(paste0(tmpdir, "/common.tar.xz"), exdir = t, tar = "internal")
    dir.create(paste0(t, "/files"), FALSE)
    setwd(t)
    tryCatch({
      inst = ""
      if(!is.null(packages) || !is.null(install_func)){
        inst = system(paste0("Rscript ", t, "/install.R"), TRUE)
      }
      log = list(
        install = inst,
        code = system(paste0("Rscript ", t, "/code.R"), TRUE))
      tmpenv = new.env()
      obj_list = load(paste0(job_dir, "/result.rda"), tmpenv)
      if((length(obj_list) == 1) && (obj_list[1] == "result")){
        if(is.null(callback_function)){
          for(val in tmpenv$result){
            result[[val$pos]] = list(log = log, result = val$res)
          }
        } else{
          for(val in tmpenv$result){
            result[[val$pos]] = list(log = log,
                                     result = callback_function(val$res))
          }
        }
        printf("OK\n")
      }else{
        printf("Error\n")
      }
    }, error = function(mess){
      stop(mess)
    }
    )
  }
  return(result)
}
