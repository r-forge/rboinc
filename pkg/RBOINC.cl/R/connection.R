# Original file name: "connection.R"
# Created: 2021.02.02
# Last modified: 2021.12.15
# License: BSD-3-clause
# Written by: Astaf'ev Sergey <seryymail@mail.ru>
# This is a part of RBOINC R package.
# Copyright (c) 2021 Karelian Research Centre of the RAS:
# Institute of Applied Mathematical Research
# All rights reserved

#' @importFrom ssh ssh_connect
#' @importFrom ssh ssh_exec_wait
#' @importFrom ssh ssh_disconnect
#' @importFrom httr handle
#' @importFrom httr POST
#' @importFrom httr GET
#' @importFrom httr cookies
#' @importFrom httr content_type
#' @importFrom askpass askpass

#' @export create_connection
#' @export close_connection

#' @title create_connection
#' @description Create a connection to the BOINC server.
#' @param server a ssh or http server URL of the form
#' \code{<}protocol\code{>}://\code{<}server name\code{>}:\code{<}port\code{>}.
#' Examples:
#' * "ssh://boinc-server.local" - for ssh connection;
#' * "http://boinc-server.local" - for http connection;
#' * "https://boinc-server.local" - for https connection.
#' @param dir a rboinc project directory on the server. For ssh connection,
#' this is the directory where the BOINC project is located. For http/https
#' connection, this is the full path to the project page (without the server
#' name).
#' @param username a string containing username. For ssh connection, this is the
#' user login. For http/https connection, this is the user email.
#' @param password a string containing user password. If this parameter is equal
#' to NULL, then a window will be displayed prompting you to enter the password
#' @param keyfile path to a private key file. For ssh connection only.
#' @return A connection (list) for use by other functions.
#' @details
#' This function create a connection to BOINC server. Don't edit the list
#' returned by this function.
#'
#' Returned object contains valid information only until the end of the current
#' R session, so don't save it to a file. Before ending the session, it is
#' recommended to release the occupied resources by calling
#' \code{\link[=close_connection]{close_connection()}}.
#'
#' \strong{ATTENTION:} ssh connections are supported but not recommended. If you
#' are the administrator for your BOINC project, see
#' https://boinc.berkeley.edu/trac/wiki/MultiUser for more information on the
#' http BOINC multiuser interface.
#' ## Errors and warnings
#' When errors occur, execution can be stopped with the following messages:
#' * for any connections:
#'   * "Unsupported server address format."
#'   * "Connection was canceled by user."
#'   * "Unrecognized protocol: "\code{<}protocol\code{>}""
#' * for http/https connections:
#'   * "Authorization failed."
#' * for ssh connections:
#'   * "Project directory was not found on server."
#' @examples
#' \dontrun{
#'
#' # For ssh connection:
#' con = create_connection(server = "ssh://boinc.local",
#'                         dir = "~/projects/myproject",
#'                         username = "boincadm",
#'                         password = "0000")
#'
#' # For http connections:
#' con = create_connection(server = "http://boinc.local",
#'                         dir = "myproject",
#'                         username = "submitter@example.com",
#'                         password = "000000")
#'
#' # For https connections:
#' con = create_connection(server = "https://boinc.local",
#'                         dir = "myproject",
#'                         username = "submitter@example.com",
#'                         password = "000000")
#' ...
#'
#' # Release resources:
#' close_connection(con)
#' }
create_connection = function(server,
                             dir = "~/projects/rboinc",
                             username,
                             password = NULL,
                             keyfile = NULL)
{
  if(!grepl("^.*://.*:[0-9]+$", server) && !grepl("^.*://.*$", server) ){
    stop("Unsupported server address format.")
  }
  # Parse server address:
  tmp = strsplit(server, "://")
  protocol = tmp[[1]][1]
  tmp = strsplit(tmp[[1]][2], ":")
  address = tmp[[1]][1]
  port = tmp[[1]][2]
  if(protocol == "ssh"){
    if(is.na(port)){
      return(connect_ssh(paste0(username, "@", address),
                         dir,
                         password,
                         keyfile))
    } else{
      return(connect_ssh(paste0(username, "@", address, ":", port),
                         dir,
                         password,
                         keyfile))
    }
  } else if((protocol == "http") || (protocol == "https")){
    auth_page = paste0(protocol, "://", address)
    if(!is.na(port)){
      auth_page = paste0(auth_page, ":", port)
    }
    handl = handle(auth_page)
    project_url = paste(auth_page, dir, sep = "/")
    auth_page = paste(auth_page, dir, "login_action.php", sep = "/")
    if(is.null(password)){
      password = askpass()
      if(is.null(password)){
        stop("Connection was canceled by user.")
      }
    }
    auth_res = POST(auth_page,
                    config =  content_type("application/x-www-form-urlencoded"),
                    body = paste0("email_addr=", username, "&passwd=", password),
                    handle = handl)
    if (is.na(match(auth_res$cookies["name"], "auth"))){
      stop("Authorization failed.")
    }
    return(list(type = "http", url = project_url, handle = handl))
  } else{
    stop("Unrecognized protocol: \"", protocol, "\".")
  }
}

connect_ssh = function(host,
                       dir = "~/projects/rboinc",
                       password = NULL,
                       keyfile = NULL)
{
  if(is.null(password) && is.null(keyfile)){
    password = askpass()
    if(is.null(password)){
      stop("Connection was canceled by user.")
    }else{
      connection = ssh_connect(host, keyfile, password)
    }
  } else if(is.null(password)){
    connection = ssh_connect(host, keyfile)
  } else if(is.null(keyfile)){
    connection = ssh_connect(host, keyfile, password)
  }
  if(!is.null(connection)){
    dir_name = ""
    if (ssh_exec_wait(connection, paste("cd ", dir, " && pwd"), function(str){dir_name <<- rawToChar(str[1:(length(str)-1)])}) != 0){
      ssh_disconnect(connection)
      stop("Project directory was not found on server.")
    }
  }
  return(list(type = "ssh", dir = dir_name, connection = connection))
}

#' @title close_connection
#' @description Disconnect from the server.
#' @param connection a connection created by
#' \code{\link[=create_connection]{create_connection()}}.
#' @return NULL
#' @details
#' This function closes the connection to the BOINC server and frees up busy
#' resources. In the case of ssh, it just calls the
#' \code{\link[ssh:ssh_disconnect]{ssh_disconnect()}} function from the ssh
#' package. In the case of the http/https interface, it looks for a link to the
#' exit page on the home page and follows it.
#' ## Errors and warnings
#' When errors occur, execution can be stopped with the following messages:
#' * for http/https connections:
#'   * "Already disconnected."
#' @inherit create_connection examples
close_connection = function(connection)
{
  if(connection$type == "ssh"){
    ssh_disconnect(connection$connection)
  } else if(connection$type == "http"){
    # Check for disconnection:
    cook = cookies(connection$handle)
    if(!("auth" %in% cook["name"])){
      stop("Already disconnected.")
    }
    # Find logout page reference
    res = GET(url = paste0(connection$url, "/home.php"),
              handle = connection$handle)
    text = rawToChar(res$content)
    match = regexpr("http.*logout.php.*\">", text, perl = TRUE)
    url = regmatches(text, match)
    url = substring(url,1,nchar(url)-2)
    url = gsub("&amp;", "&", url)
    res = GET(url, handle = connection$handle)
  }
  NULL
}
