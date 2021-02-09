# Original file name: "connection.R"
# Created: 2021.02.02
# Last modified: 2021.02.02
# License: Comming soon
# Written by: Astaf'ev Sergey <seryymail@mail.ru>
# This is a part of RBOINC R package.

#' @importFrom ssh ssh_connect
#' @importFrom ssh ssh_exec_wait
#' @importFrom ssh ssh_disconnect

#' @export create_connection
#' @export close_connection

#' @title create_connection
#' @description Create a ssh session.
#' @param host a ssh server string of the form <user@>hostname<:@port>.
#' @param dir a rboinc project dir on server.
#' @param password a string containing user password.
#' @param keyfile path to private key file.
#' @return a connection (list) for use by other functions.
#' @inherit create_jobs examples
create_connection = function(host, dir = "~/projects/rboinc", password = NULL, keyfile = NULL)
{
  connection = tryCatch({
    if (is.null(password)){
      ssh_connect(host, keyfile)
    }else{
      ssh_connect(host, keyfile, password)
    }
  },error = function(cond){
    return(NULL)
  },warning = function(cond){
    return(NULL)
  })
  if(!is.null(connection)){
    if (ssh_exec_wait(connection, paste("cd ", dir)) != 0){
      ssh_disconnect(connection)
      return(NULL)
    }
  }
  return(list(dir = dir, connection = connection))
}

#' @title close_connection
#' @description Disconnect connection.
#' @param connection a connection created by create_connection
#' @inherit create_jobs exampless
close_connection = function(connection)
{
  return(ssh_disconnect(connection$connection))
}
