#!/bin/bash
l=/data/logs/seafile.log
d=/data/seafile

trap '{ $d/seafile.sh stop; exit 0; }' EXIT 
$d/seafile.sh start 
tail -f -n1 $l
