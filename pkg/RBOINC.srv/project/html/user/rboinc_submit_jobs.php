<?php
// Original file name: "rboinc_submit_jobs.php"
// Created: 2021.02.15
// Last modified: 2021.02.16
// License: Comming soon
// Written by: Astaf'ev Sergey <seryymail@mail.ru>
// This is a part of RBOINC R package.

require_once("../inc/submit_db.inc");
require_once("../inc/util.inc");
require_once(dirname(__FILE__) . "/../../rboinc/bin/prefix.inc");

$user = get_logged_in_user();
// Check user privileges
$user_submit = BoincUserSubmit::lookup_userid($user->id);
if (!$user_submit){
  echo 1;
  exit(0);
}


$file_prefix = get_file_prefix();
$upload_dir = dirname(__FILE__) . "/../../rboinc/uploads/" . $file_prefix;
$project_dir = dirname(__FILE__) . "/../../";

umask(0000);
mkdir($upload_dir, 0777, true);

$upload_file = $upload_dir . "/archive.tar.xz";

if(move_uploaded_file($_FILES['userfile']['tmp_name'], $upload_file)){
  // Unpack archive
  exec("tar -xf $upload_file -C $upload_dir");
  unlink($upload_file);
  // Add prefix for all files
  rename($upload_dir . "/common.tar.xz", $upload_dir ."/" . $file_prefix . "common.tar.xz");
  chdir($upload_dir . "/data");
  exec("for f in * ; do mv -- \"\$f\" \"" . $file_prefix . "\$f\" ; done");
  // Get jobs count
  $data_count = count(glob($upload_dir . "/data/*"));
  // Stage files
  chdir($project_dir);
  exec("bin/stage_file " . $upload_dir . "/" . $file_prefix . "common.tar.xz");
  exec("bin/stage_file " . $upload_dir . "/data");
  rmdir($upload_dir . "/data");
  rmdir($upload_dir);
  echo 0;
} else {
  echo 2;
}

?>
