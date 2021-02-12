# Original file name: "connection.R"
# Created: 2021.02.02
# Last modified: 2021.02.12
# License: Comming soon
# Written by: Astaf'ev Sergey <seryymail@mail.ru>
# This is a part of RBOINC R package.

#' @importFrom ssh ssh_connect
#' @importFrom ssh ssh_exec_wait
#' @importFrom ssh ssh_disconnect
#' @importFrom httr handle
#' @importFrom httr POST
#' @importFrom httr GET
#' @importFrom httr handle_reset
#' @importFrom httr content_type
#' @importFrom askpass askpass

#' @export create_connection
#' @export close_connection

#' @title create_connection
#' @description Create a ssh or http/https connection to server.
#' @param server a ssh or http server string of the form <protocol>://<server name>:<port>. Examples:
#' * "ssh://boinc-server.local" - for ssh connection;
#' * "http://boinc-server.local" - for http connection;
#' * "https://boinc-server.local" - for https connection.
#' @param dir a rboinc project dir on server. For ssh connection, this is the directory where the BOINC project is located.
#' For http/https connection, this is the full path to the project page (without the server name).
#' @param username a string containing username. For ssh connection, this is user login. For http/https connection, this is
#' user email.
#' @param password a string containing user password.
#' @param keyfile path to private key file. For ssh connection only.
#' @return a connection (list) for use by other functions.
#' @inherit create_jobs examples
create_connection = function(server, dir = "~/projects/rboinc", username, password = NULL, keyfile = NULL)
{
  tmp = strsplit(server, "://")
  protocol = tmp[[1]][1]
  tmp = strsplit(tmp[[1]][2], ":")
  address = tmp[[1]][1]
  port = tmp[[1]][2]
  if(protocol == "ssh"){
    if(is.na(port)){
      return(connect_ssh(paste0(username, "@", address), dir, password, keyfile))
    } else{
      return(connect_ssh(paste0(username, "@", address, ":@", port), dir, password, keyfile))
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
    }
    auth_res = POST(auth_page, config =  content_type("application/x-www-form-urlencoded"),
                    body = paste0("email_addr=", username, "&passwd=", password), handle = handl)
    if (is.na(match(auth_res$cookies["name"], "auth"))){
      handle_reset(handl)
      return(NULL)
    }
    return(list(type = "http", url = project_url, handle = handl))
  } else{
    return(NULL)
  }
}

connect_ssh = function(host, dir = "~/projects/rboinc", password = NULL, keyfile = NULL)
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
  return(list(type = "ssh", dir = dir, connection = connection))
}

#' @title close_connection
#' @description Disconnect connection.
#' @param connection a connection created by create_connection
#' @inherit create_jobs examples
close_connection = function(connection)
{
  if(connection$type == "ssh"){
    ssh_disconnect(connection$connection)
  } else if(connection$type == "http"){
    # Find logout page reference
    res = GET(url = paste0(con$url, "/home.php"), handle = con$handle)
    text = rawToChar(res$content)
    match = regexpr("http.*logout.php.*\">", text, perl = TRUE)
    url = regmatches(text, match)
    url = substring(url,1,nchar(url)-2)
    url = gsub("&amp;", "&", url)
    res = GET(url, handle = con$handle)
  }
}
