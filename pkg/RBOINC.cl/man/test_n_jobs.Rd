% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/testAPI.R
\name{test_n_jobs}
\alias{test_n_jobs}
\title{test_n_jobs}
\usage{
test_n_jobs(
  work_func,
  data,
  n,
  init_func = NULL,
  global_vars = NULL,
  packages = c(),
  files = c(),
  callback_function = NULL
)
}
\arguments{
\item{work_func}{data processing function. This function runs for each
element in data. This function can be recursive.}

\item{data}{data for processing.  Must be a numerable list or vector.}

\item{n}{a number of jobs. This parameter must be less than or equal to the
length of the data.}

\item{init_func}{initialization function. This function runs once at the
start of a job before the job is split into separate threads. Necessary for
additional initialization, for example, for compiling C++ functions from
sources transferred through files parameter. This function can not to be
recursive.}

\item{global_vars}{a list in the format
\code{<}variable name\code{>}=\code{<}value\code{>}.}

\item{packages}{a string vector with imported packages names.}

\item{files}{a string vector with the files names that should be available
for jobs.}

\item{callback_function}{a function that is called for each result after
loading. This function must take one argument, which is the result of the
work performed. The value returned by this function is placed in the result
list.}
}
\value{
a list with states of jobs. This list contains the following fields:
\itemize{
\item log - Rscript output;
\item result - computation result.
When errors occur, execution can be stopped with the following messages:
\item for any connection:
\itemize{
\item "Archive making error: \code{<}error message\code{>}"
}
}
}
\description{
Like create_n_jobs, it creates a jobs for the BOINC server but
does not submit them. Instead, it runs all jobs locally and generates a
report at each step. This function is intended for debugging applications
that use RBOINC. Files created by this function are not deleted after its
completion.
}
\examples{
\dontrun{
# import library
library(RBOINC.cl)
# function for data processing
fun = function(val)
{
  return(val * a + b)
}
# global variables
glob_vars = list(a = 3, b = 2)
# Initialization function. This function runs on each node for one times.
init = function()
{
  return(NULL)
}
# data for processing
data = list(matrix(rexp(15), 3,5), matrix(rexp(15), 3,5))

#callback function
print_func = function(val)
{
  print(val)
  # May be any value
  return(val)
  #return(NULL)
}

# Test jobs before sending
jobs_t = test_jobs(fun, data, init, glob_vars, callback_function = print_func)
jobs_t
jobs_t = test_n_jobs(fun, data, 1, init, glob_vars, callback_function = print_func)
jobs_t

# Create connection:
#con = create_connection("ssh://boinc.local", "~/projects/myproject", "boincadm", "0000") # ssh
#con = create_connection("http://boinc.local", "myproject", "submitter@example.com","000000")# http
con
# send jobs:
#jobs = create_jobs(con, fun, data, init, glob_vars)
#jobs = create_n_jobs(con, fun, data, 1, init, glob_vars)
jobs
# Get jobs status. Run this until status not equal "done":
jobs = update_jobs_status(con, jobs)
jobs
# Close connection:
close_connection(con)
}
}
