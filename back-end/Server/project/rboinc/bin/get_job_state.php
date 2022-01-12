#! /usr/bin/env php
<?php
// Original file name: "get_next_number.php"
// Created: 2021.02.08
// Last modified: 2021.10.25
// License: BSD-3-clause
// Written by: Astaf'ev Sergey <seryymail@mail.ru>
// This is a part of RBOINC R package.
// Copyright (c) 2021-2022 Karelian Research Centre of
// the RAS: Institute of Applied Mathematical Research
// All rights reserved

// Get job status by name

// Exit statuses:
// 0 - OK
// 1 - running not in BOINC project dir
// 2 - wrong running parameters
// 3 - file not found
// 4 - job not exist
// 5 - other errors
// 6 - job in processing

if(!file_exists("config.xml")){
    echo "Run this script in BOINC project dir.\n";
    exit(1);
}

if($argc != 2){
    echo "usage: get_job_state.php <job name>\n";
    exit(2);
}

chdir("./html/inc");
require_once("boinc_db.inc");
chdir("../..");
$job_name =  $argv[1];

$state = BoincWorkunit::lookup("name='$job_name'");

if(!$state){
    echo "job_not_exist";
    exit(4);
}

if($state->error_mask){
    echo "error_code:" . $state->error_mask;
    exit(5);
}

if($state->assimilate_state == 2){
    $res_file = "download/rboinc/" . $job_name;
    if(!file_exists($res_file)){
        echo $res_file . " not found.";
        exit(3);
    }
    echo "done";
    exit(0);
}

echo "in_progress";
exit(6);
?>
