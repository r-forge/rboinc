// Original file name: "main.cpp"
// Created: 2021.03.30
// Last modified: 2021.10.22
// License: BSD-3-clause
// Written by: Astaf'ev Sergey <seryymail@mail.ru>
// Description: This is universal validator for any R code results.
// This is a part of RBOINC R package.
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
ret = 3 \n\
try(expr = {\n\
  file = commandArgs(trailingOnly=TRUE)[1]\n\
  test_env = new.env()\n\
  load(file, test_env)\n\
  if((length(test_env) == 1) && ('result' %in% names(test_env)) && (is.list(test_env\\$result))){\n\
    ret <<- 0\n\
    for(val in test_env\\$result){\n\
      nm = names(val)\n\
      if((length(val) != 2) || !('res' %in% nm) || !('pos' %in% nm)){\n\
        ret <<- 1\n\
        break\n\
      }\n\
    }\n\
  }else {\n\
    ret <<- 2\n\
  }\n\
}, silent = TRUE)\n\
quit('no', ret)\" \0";

char *cmd_string;

int validate_handler_init(int argc, char** argv)
{
    unsigned long int size = PATH_MAX + strlen(test_script);
    cmd_string = (char*)malloc(size + 1);
    memcpy((void*)cmd_string, (void*)test_script, strlen(test_script) + 1);
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
    memcpy((void*)(cmd_string + strlen(test_script)), (void*)filename, strlen(filename));
    cmd_string[strlen(filename) + strlen(test_script)] = '\0';
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
