<?php
// Original file name: "prefix.inc"
// Created: 2021.02.11
// Last modified: 2021.02.11
// License: BSD-3-clause
// Written by: Astaf'ev Sergey <seryymail@mail.ru>
// This is a part of RBOINC R package.
// Copyright (c) 2021-2022 Karelian Research Centre of
// the RAS: Institute of Applied Mathematical Research
// All rights reserved

function get_next_number($file_name)
{
  $fd = fopen(dirname(__FILE__) . "/../cache/" . $file_name, 'c+') or die();

  if (flock($fd, LOCK_EX)){
      fseek($fd, 0, SEEK_END);
      $file_size = ftell($fd);
      if($file_size == 0){
          fwrite($fd, "2");
          flock($fd, LOCK_UN);
          fclose($fd);
          return(1);
      } else {
          rewind($fd);
          $num = fread($fd, $file_size);
          $ret = $num;
          $num = ((int)$num + 1) % 2147483647;
          if($num == 0){
              $num = 1;
          }
          rewind($fd);
          ftruncate($fd, 0);
          fwrite($fd, (string)$num);
          flock($fd, LOCK_UN);
          fclose($fd);
          return($ret);
      }
  }else {
      return(0);
  }
}

function get_file_prefix()
{
  $now = DateTime::createFromFormat('U.u', microtime(true));
  return($now->format("Y_m_d_h_i_s_u") . "_" . get_next_number("file_number.count") . "_");
}

function get_job_name()
{
  $now = DateTime::createFromFormat('U.u', microtime(true));
  return("rboinc_" . $now->format("Y_m_d_h_i_s.u") . "." . get_next_number("job_number.count"));
}
?>
