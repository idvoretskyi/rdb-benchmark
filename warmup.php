<?php

include 'rdb/rdb.php';

$conn = r\connect('localhost', 28015);

echo r\db('ycsb')->table('usertable')->map(function ($r) {return r\expr(1);} )->count()->run($conn) . "\n";

?>

