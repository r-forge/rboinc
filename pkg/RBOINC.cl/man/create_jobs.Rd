% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/createJob.R
\name{create_jobs}
\alias{create_jobs}
\title{create_jobs}
\usage{
create_jobs(
  connection,
  work_func,
  data,
  init_func = NULL,
  global_vars = NULL,
  packages = c(),
  files = c()
)
}
\arguments{
\item{connection}{a connection created by create_connection.}

\item{work_func}{data processing function. This function runs for each
element in data. This function can be recursive.}

\item{data}{data for processing.  Must be a numerable list or vector.}

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
}
\value{
a list with current states of jobs. This list contains the following
fields:
\itemize{
\item jobs_name - a name of job on BOINC server;
\item results - computation results (NULL if computation is still incomplete).
The length of this list is equal to the length of the data;
\item jobs_status - jobs human-readable status for each job;
\item jobs_code - jobs status code, don't use this field;
\item status - computation status, may be:
\itemize{
\item "initialization" - jobs have been submitted to the server, but their
status was not requested by update_jobs_status.
\item "in_progress" - BOINC serves jobs.
\item "done" - computations are complete, the result was downloaded.
\item "error" - an error occurred during the job processing.
\item "queued" - job in the queue (only for http/https connections).
}
}
}
\description{
Send job to BOINC server for parallel processing. This function
creates the number of tasks equal to the length of the data.
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
