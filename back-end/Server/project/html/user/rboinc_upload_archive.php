<?php
// Original file name: "rboinc_upload_archive.php"
// Created: 2021.02.15
// Last modified: 2021.07.23
// License: BSD-3-clause
// Written by: Astaf'ev Sergey <seryymail@mail.ru>
// This is a part of RBOINC R package.
// Copyright (c) 2021 Karelian Research Centre of the RAS:
// Institute of Applied Mathematical Research
// All rights reserved

require_once("../inc/submit_db.inc");
require_once("../inc/util.inc");
require_once(dirname(__FILE__) . "/../../rboinc/bin/prefix.inc");

$user = get_logged_in_user();

// Check user privileges
$user_submit = BoincUserSubmit::lookup_userid($user->id);
if (!$user_submit){
  header('HTTP/1.0 403 Forbidden');
  echo "Access denied.";
  exit(0);
}

// Check file uploading
if(!isset($_FILES['archive'])){
  echo "This script only for low-level file uploading.";
  exit(0);
}


$file_prefix = get_file_prefix();
$upload_dir = dirname(__FILE__) . "/../../rboinc/uploads/" . $file_prefix;
$project_dir = dirname(__FILE__) . "/../../";

umask(0000);
mkdir($upload_dir, 0775, true);
umask(0022);

$upload_file = $upload_dir . "/archive.tar.xz";

if(move_uploaded_file($_FILES['archive']['tmp_name'], $upload_file)){
  // Unpack archive
  exec("tar -xf $upload_file -C $upload_dir");
  unlink($upload_file);
  // Add prefix for all files
  rename($upload_dir . "/common.tar.xz", $upload_dir ."/" . $file_prefix . "common.tar.xz");
  chdir($upload_dir . "/data");
  exec("for f in * ; do mv -- \"\$f\" \"" . $file_prefix . "\$f\" ; done");
  // Get data files count
  $data_count = count(glob($upload_dir . "/data/*"));
  // Make output xml
  $result_xml = "<staged_files>\n";
  $result_xml .= "  <common>" . $file_prefix . "common.tar.xz</common>\n";
  $result_xml .= "  <data>\n";
  for($i = 0; $i < $data_count; $i++){
    $result_xml .= "<val_" . $i . ">" . $file_prefix . $i . ".rda</val_" . $i . ">\n";
  }
  $result_xml .= "  </data>\n";
  $result_xml .= "</staged_files>";
  // Stage files
  chdir($project_dir);
  exec("bin/stage_file " . $upload_dir . "/" . $file_prefix . "common.tar.xz");
  exec("bin/stage_file " . $upload_dir . "/data");
  rmdir($upload_dir . "/data");
  rmdir($upload_dir);
  header("Content-type: text/xml");
  echo $result_xml;
} else {
  echo "Error";
}

?>
