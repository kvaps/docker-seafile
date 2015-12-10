#!/bin/bash
l=/data/logs/ccnet.log
d=/data/seafile

trap '{ $d/seafile.sh stop; exit 0; }' EXIT 
$d/seahub.sh start 
tail -f -n1 $l
