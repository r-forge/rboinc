// Original file name: "main.cpp"
// Created: 2021.03.30
// Last modified: 2021.10.25
// License: BSD-3-clause
// Written by: Astaf'ev Sergey <seryymail@mail.ru>
// Description: This is universal validator for any R code results.
// This is a part of RBOINC R package.
// Copyright (c) 2021-2022 Karelian Research Centre of
// the RAS: Institute of Applied Mathematical Research
// All rights reserved
#include <cstdlib>
#include <cstring>
#include <validate_util2.h>
#include <validate_util.h>
#include <error_numbers.h>
#include <sched_util.h>
#include <unistd.h>
#include <limits.h>


// R test script.
const char* test_script = "Rscript -e \"\
retval = 3 \n\
try(expr = {\n\
  file = commandArgs(trailingOnly=TRUE)[1]\n\
  test_env = new.env()\n\
  load(file, test_env)\n\
  ret = 0\n\
  if((length(test_env) == 1) && ('result' %in% names(test_env)) && (is.list(test_env\\$result))){\n\
    for(val in test_env\\$result){\n\
      nm = names(val)\n\
      if((length(val) != 2) || !('res' %in% nm) || !('pos' %in% nm)){\n\
        ret = 1\n\
        break\n\
      }\n\
    }\n\
  }else {\n\
    ret = 2\n\
  }\n\
  retval <<- ret \n\
}, silent = TRUE)\n\
quit('no', retval)\" \0";

char *cmd_string;
unsigned int script_len;

int validate_handler_init(int argc, char** argv)
{
    script_len = strlen(test_script);
    unsigned long int size = PATH_MAX + script_len;
    cmd_string = (char*)malloc(size + 1);
    memcpy((void*)cmd_string, (void*)test_script, script_len + 1);
    return 0;
}

void validate_handler_usage()
{
}

int init_result(RESULT& result, void*& data)
{
    // Get file name:
    OUTPUT_FILE_INFO fi;
    int ret = get_output_file_path(result, fi.path);
    if (ret) return ret;
    const char* filename = fi.path.c_str();
    //Check file existence and readable:
    if(access(filename, F_OK) == 0){
        if(access(filename, R_OK)){
            return ERR_READ;
        }
    } else {
        return ERR_FOPEN;
    }
    // Check file format:
    unsigned int filename_len = strlen(filename);
    memcpy((void*)(cmd_string + script_len), (void*)filename, filename_len);
    cmd_string[filename_len + script_len] = '\0';
    return system(cmd_string);
}

int compare_results(RESULT& r1, void* data1, RESULT const& r2, void* data2, bool& match)
{
    match = true;
    return 0;
}

int cleanup_result(RESULT const& r, void* data)
{
    return 0;
}
