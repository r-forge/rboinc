# Original file name: "testAPI.R"
# Created: 2021.03.19
# Last modified: 2021.08.25
# License: BSD-3-clause
# Written by: Astaf'ev Sergey <seryymail@mail.ru>
# This is a part of RBOINC R package.
# Copyright (c) 2021 Karelian Research Centre of the RAS:
# Institute of Applied Mathematical Research
# All rights reserved

#' @importFrom R.utils printf
#' @importFrom utils untar

# The next line was added only to add foreach to the list of dependencies.
# foreach is used by the generated script and therefore is required by the
# functions from the testAPI.R
#' @importFrom foreach foreach

#' @export test_jobs

#' @title test_jobs
#' @description Like create_n_jobs, it creates a jobs for the BOINC server but
#' does not submit them. Instead, it runs all jobs locally and generates a
#' report at each step. This function is intended for debugging applications
#' that use RBOINC. Files created by this function are not deleted after its
#' completion.
#' @inherit create_jobs params
#' @inherit update_jobs_status params
#' @return a list with states of jobs. This list contains the following fields:
#' * log - Rscript output;
#' * result - computation result.
#' When errors occur, execution can be stopped with the following messages:
#' * for any connection:
#'   * "Archive making error: \code{<}error message\code{>}"
#' @inherit create_jobs examples
test_jobs = function(work_func,
                       data,
                       n = NULL,
                       init_func = NULL,
                       global_vars = NULL,
                       packages = c(),
                       files = c(),
                       callback_function = NULL)
{
  old_wd = getwd()
  on.exit(setwd(old_wd), TRUE)
  if(is.null(n)){
    n = length(data)
  }
  printf("Testing archive making...\t")
  lst = split_list(data, n)
  ar = make_archive(work_func,
                    deparse(substitute(work_func)),
                    lst,
                    init_func,
                    global_vars,
                    packages,
                    files)
  if(is.null(ar)){
    printf("Error\n")
    return(NULL)
  } else{
    printf("OK: %s\n",ar)
  }
  printf("Creating tmp dir for test...\t")
  tmpdir = tempfile()
  dir.create(tmpdir)
  if(dir.exists(tmpdir)){
    printf("OK: %s\n",tmpdir)
  }else {
    printf("Error\n")
    return(NULL)
  }

  # Workaround for bsdtar 3.3.2 bug. For some tar.xz arhives bsdtar 3.3.2
  # freezes when unpacking.
  tar_version = tryCatch({
    untar("", extras = "--version", list = TRUE)
  },error=function(cond){
    return("unknown_version")
  }
  )
  tar_version = substr(tar_version, 1, 12)[1]
  if(tar_version == "bsdtar 3.3.2"){
    printf("!!!Warning: bsdtar 3.3.2 detected!!! Installing workaround...\t")
    decompress = function(file, exdir){
      file.copy(file, exdir)
      bname = basename(file)
      ret = system(paste0("xz -d -qq ", exdir, "/", bname))
      if(ret != 0){
        return(ret)
      }
      ret = system(paste0("tar -xf ", exdir, "/", substr(bname, 1, nchar(bname) - 3), " -C ", exdir))
      return (ret)
    }
    printf("OK.\n")
  } else{
    decompress = untar
  }

  printf("Testing archive unpacking...\t")
  if(decompress(ar, exdir = tmpdir) == 0){
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
  dir.create(job_dir)
  dir.create(paste0(job_dir, "/shared"))
  for(val in jobs){
    t = paste0(job_dir, "/", basename(val))
    printf("Running job %s in %s ", val, t)
    dir.create(t)
    file.copy(paste0(tmpdir, "/data/", val), paste0(t, "/data.rda"))
    decompress(paste0(tmpdir, "/common.tar.xz"), exdir = t)
    dir.create(paste0(t, "/files"), FALSE)
    setwd(t)
    tryCatch({
      log = system(paste0("Rscript ", t, "/code.R "), TRUE)
      tmpenv = new.env()
      obj_list = load(paste0(job_dir, "/shared/result.rda"), tmpenv)
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
