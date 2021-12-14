# Original file name: "necromancer.R"
# Created: 2021.12.14
# Last modified: 2021.12.14
# License: BSD-3-clause
# Written by: Astaf'ev Sergey <seryymail@mail.ru>
# This is a part of RBOINC R package.
# Copyright (c) 2021 Karelian Research Centre of the RAS:
# Institute of Applied Mathematical Research
# All rights reserved

#' @importFrom utils tar
#' @importFrom utils untar

pkg.env <- new.env()
pkg.env$is_default_compress_implementation = TRUE
pkg.env$is_default_decompress_implementation = TRUE

virtual_compress = function(tarfile, files = NULL)
{
  if(pkg.env$is_default_compress_implementation){
    return(tar(tarfile, files, compression = "xz"))
  }else{
    return(tar(tarfile, files, compression = "xz", tar = "tar"))
  }
}

virtual_decompress = function(file, directory = ".")
{
  if(pkg.env$is_default_decompress_implementation){
    return(untar(file, exdir = directory))
  }else{
    file.copy(file, directory)
    bname = basename(file)
    ret = system(paste0("xz -d -qq ", directory, "/", bname))
    if(ret != 0){
      return(ret)
    }
    ret = system(paste0("tar -xf ", directory, "/", substr(bname, 1, nchar(bname) - 3), " -C ", directory))
    return (ret)
  }
}


get_compression_mode = function(tar_version = "")
{
  tmp_file = tempfile()
  tmp_dir = tempdir(TRUE)
  tar_file = paste0(tmp_dir, "/test.tar")
  file.create(tmp_file)
  flag = tryCatch({
      tar(tar_file, tmp_file, compression = "xz")
      TRUE
    },warning = function(mess){
      return(FALSE)
    },error = function(mess){
      return(FALSE)
    })
  if(flag){
    return(TRUE)
  }else{
    return(FALSE)
  }
}

.onLoad <- function(libname, pkgname) {
  # Workaround for bug #6752:
  if((Sys.getenv("tar") == "") && (version$major < 4)){
    print("Sys.getenv did not find tar and R version < 4.0. Trying to install workaround for compression...")
    tar_version = tryCatch(
      system("tar --version", intern = TRUE )[1],
      error = function(mess){
        return("not_found")
      })
    if(tar_version == "not_found"){
      print("FAIL: tar not found in your system. Using default R implementation. Please, install tar and xz.")
    }else{
      print(paste0("Detected: ", tar_version, " Checking how tar works..."))
      if (get_compression_mode()){
        pkg.env$is_default_compress_implementation = FALSE
        print("SUCCESS: workaround for compression installed.")
      } else {
        print("FAIL: xz algorithms is not supported by your tar. Please, install tar and xz.")
      }
    }
  }
  # Workaround for bsdtar 3.3.x bug.
  # For some tar.xz arhives bsdtar 3.3.2 freezes when unpacking.
  tar_version = tryCatch({
    untar("", extras = "--version", list = TRUE)
  },error=function(cond){
    return("unknown_version")
  })
  tar_version = substr(tar_version, 1, 11)[1]
  if(tar_version == "bsdtar 3.3."){
    print("bsdtar 3.3.x detected. Trying to install workaround for decompression...")
    default_warn = getOption("warn")
    options(warn = -1)
    if((system("tar --version", ignore.stdout = TRUE, ignore.stderr = TRUE) == 0) && 
       (system("xz --version", ignore.stdout = TRUE, ignore.stderr = TRUE) == 0)){
      pkg.env$is_default_decompress_implementation = FALSE
      print("SUCCESS: workaround for decompression installed.")
    }else{
      print("FAIL: Please, install tar and xz.")
    }
    options(warn = default_warn)
  }
}