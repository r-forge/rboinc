// Original file name: "main.cpp"
// Created: 2021.03.30
// Last modified: 2021.03.31
// License: Comming soon
// Written by: Astaf'ev Sergey <seryymail@mail.ru>
// Description: This is universal validator for any R code results.
// This is a part of RBOINC R package.
#include <RInside.h>
#include <string>
#include <iostream>
#include <validate_util2.h>
#include <validate_util.h>
#include <error_numbers.h>
#include <sched_util.h>
#include <unistd.h>

using namespace std;

// R test script.
string test_script = "\
result = tryCatch({\n\
  test_env = new.env()\n\
  load(file, test_env)\n\
  if((length(test_env) == 1) && (!is.null(test_env$result))){\n\
    TRUE\n\
  } else {\n\
    FALSE\n\
  }\n\
}, error = function(cond){return(FALSE)}, warning = function(cond){return(FALSE)})";

// R interpreter.
RInside R_int;

int validate_handler_init(int argc, char** argv)
{
	return 0;
}

void validate_handler_usage()
{
}

int init_result(RESULT& result, void*& data)
{
	 // Get file name.
        OUTPUT_FILE_INFO fi;
        int ret = get_output_file_path(result, fi.path);
        if (ret) return ret;
        const char* filename = fi.path.c_str();
        //Check file existence and readable.
        if(access(filename, F_OK) == 0){
                if(access(filename, R_OK)){
                        return ERR_READ;
                }
        } else {
                return ERR_FOPEN;
        }
        // Check file format.
        R_int["file"] = filename;
        R_int.parseEvalQ(test_script);
	bool test_res = bool(R_int["result"]);
	R_int.parseEvalQ("rm(list = ls())");
        if(test_res == TRUE){
                return 0;
        } else {
                return 1;
        }
	return 0;
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
