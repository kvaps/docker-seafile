#!/bin/bash
l=/data/logs/ccnet.log
d=/data/seafile

trap '{ $d/seahub.sh stop; exit 0; }' EXIT 
sleep 5
$d/seahub.sh start-fastcgi
tail -f -n1 $l
