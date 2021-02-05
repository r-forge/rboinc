#! /usr/bin/env php
<?php
// Original file name: "get_next_number.php"
// Created: 2021.02.04
// Last modified: 2021.02.05
// License: Comming soon
// Written by: Astaf'ev Sergey <seryymail@mail.ru>
// This is a part of RBOINC R package.

// Get unique number for saving file.
// Usage:./get_next_number <counter file>

if($argc <> 2){
    exit(2);
}

$fd = fopen(dirname(__FILE__) . "/../cache/" . $argv[1], 'c+') or die();

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
    exit(1);
}
?>
