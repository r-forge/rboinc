# Original file name: "httpSender.R"
# Created: 2021.10.20
# Last modified: 2021.12.15
# License: BSD-3-clause
# Written by: Astaf'ev Sergey <seryymail@mail.ru>
# This is a part of RBOINC R package.
# Copyright (c) 2021-2022 Karelian Research Centre of
# the RAS: Institute of Applied Mathematical Research
# All rights reserved

#' @importFrom httr POST
#' @importFrom httr cookies
#' @importFrom httr content

send_http_message_to_server = function(connection, type, params)
{
  # Get user auth ID
  cook = cookies(connection$handle)
  auth = cook[cook["name"]=="auth", "value"]
  # Build message :
  message_xml = paste0(
    "<", type , ">",
      "<authenticator>", auth, "</authenticator>")
  name = names(params)
  for(k in seq_len(length(params))){
    message_xml = paste0(message_xml,
      "<", name[k], ">", params[[k]], "</", name[k], ">")
  }
  message_xml = paste0(message_xml,
    "</", type , ">"
  )
  # Send message:
  ret = content(POST(url = paste0(connection$url,"/submit_rpc_handler.php"),
                     body = list(request = message_xml),
                     handle = connection$handle,
                     set_cookies(obtain_cookies(connection))))
  return(ret)
}
