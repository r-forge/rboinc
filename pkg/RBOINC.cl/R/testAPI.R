# Original file name: "testAPI.R"
# Created: 2021.03.19
# Last modified: 2021.03.19
# License: Comming soon
# Written by: Astaf'ev Sergey <seryymail@mail.ru>
# This is a part of RBOINC R package.

#' @importFrom R.utils printf

#' @export test_jobs

#' @title test_jobs
#' @description Like create_jobs, it creates a job for the BOINC server but does not submit it. Instead, it runs the job locally and generates a report at each step. This function is intended for debugging applications that use RBOINC. Files created by this function are not deleted after its completion.
#' @inherit create_jobs params
#' @return a list with states of jobs. This list contains the following fields:
#' * log - Rscript output;
#' * result - computation result.
#' @inherit create_jobs examples
test_jobs = function(work_func, data, init_func = NULL, global_vars = NULL, packages = c(), files = c())
{
  printf("Testing archive making...\t")
  ar = make_archive(work_func, deparse(substitute(work_func)), data, init_func, global_vars, packages, files)
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

  # Workaround for bsdtar 3.3.2 bug. For some tar.xz arhives bsdtar 3.3.2 freezes when unpacking.
  tar_version = tryCatch({
      untar("", extras = "--version", list = TRUE)
    },error=function(cond){
      return("unknown_version")
    }
  )
  tar_version = substr(tar_version, 1, 12)
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
  result = list()
  job_dir = tempfile()
  dir.create(job_dir)
  dir.create(paste0(job_dir, "/shared"))
  for(val in jobs){
    t = paste0(job_dir, "/", basename(val))
    printf("Running job %s in %s ", val, t)
    dir.create(t)
    file.copy(paste0(tmpdir, "/data/", val), paste0(t, "/data.rbs"))
    decompress(paste0(tmpdir, "/common.tar.xz"), exdir = t)
    dir.create(paste0(t, "/files"), FALSE)
    oldwd = getwd()
    setwd(t)
    log = system(paste0("Rscript ", t, "/code.R "), TRUE)
    tmpenv = new.env()
    obj_list = load(paste0(job_dir, "/shared/result.rbs"), tmpenv)
    if((length(obj_list) == 1) && (obj_list[1] == "result")){
      result[[length(result)+1]] = list(log = log, result = tmpenv$result)
      printf("OK\n")
    }else{
      printf("Error\n")
    }
    setwd(oldwd)
  }
  return(result)
}
