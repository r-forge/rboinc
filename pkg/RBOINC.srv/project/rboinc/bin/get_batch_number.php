#! /usr/bin/env php
<?php
// Original file name: "get_batch_number"
// Created: 2021.02.04
// Last modified: 2021.02.04
// License: Comming soon
// Written by: Astaf'ev Sergey <seryymail@mail.ru>
// This is a part of RBOINC R package.

// Get unique number for creating batch of jobs.

if (!file_exists("config.xml")) {
    error_exit("This script must be run in the BOINC project directory.\n");
}

$fd = fopen("./rboinc/cache/batch_number.count", 'c+') or die();

if (flock($fd, LOCK_EX)){
    fseek($fd, 0, SEEK_END);
    $file_size = ftell($fd);
    if($file_size == 0){
        echo 1;
        fwrite($fd, "2");
        flock($fd, LOCK_UN);
        fclose($fd);
    } else {
        rewind($fd);
        $num = fread($fd, $file_size);
        echo $num;
        $num = ((int)$num + 1) % 2147483647;
        if($num == 0){
            $num = 1;
        }
        rewind($fd);
        ftruncate($fd, 0);
        fwrite($fd, (string)$num);
        flock($fd, LOCK_UN);
        fclose($fd);
    }
}else {
    error_exit("Can't lock file.\n");
}
?>
