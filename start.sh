#!/bin/bash

expect <<EOF
spawn   ./setup-seafile-mysql.sh
set timeout 300
expect  "Press ENTER to continue"
send    "\r"
expect  " server name "
send    "test\r"
expect  " This server's ip or domain "
send    "0.0.0.0\r"
expect  " default "
send    "/data/seafile-data\r"
expect  " default \"8082\" "
send    "8082\r"
expect  " 1 or 2 "
send    "1\r"
expect  " default \"localhost\" "
send    "seafile-db\r"
expect  " default \"3306\" "
send    "3306\r"
expect  " mysql user for seafile "
send    "seafile\r"
expect  " password for * "
send    "seafile\r"
expect  " ccnet database "
send    "seafile\r"
expect  " seafile database "
send    "seafile\r"
expect  " seahub database "
send    "seafile\r"
expect  "Press ENTER to continue"
send    "\r"
expect  "Your seafile server configuration has been finished successfully."
exit    0
EOF

expect <<EOF
spawn   ./setup-seafile-mysql.sh
set timeout 300
expect  "Press ENTER to continue"
send    "\r"
expect  " server name "
send    "test\r"
expect  " This server's ip or domain "
send    "0.0.0.0\r"
expect  " default "
send    "/data/seafile-data\r"
expect  " default \"8082\" "
send    "8082\r"
expect  " 1 or 2 "
send    "1\r"
expect  " default \"localhost\" "
send    "seafile-db\r"
expect  " default \"3306\" "
send    "3306\r"
expect  " root password "
send    "seafile\r"
expect  " default \"root\" "
send    "root\r"
expect  " default \"ccnet-db\" "
send    "ccnet-db\r"
expect  " default \"seafile-db\" "
send    "seafile-db\r"
expect  " default \"seahub-db\" "
send    "seahub-db\r"
expect  "Press ENTER to continue"
send    "\r"
expect  "Your seafile server configuration has been finished successfully."
exit    0
EOF

./seafile.sh start

expect <<EOF
spawn   ./seahub.sh start
set timeout 300
expect  " admin email "
send    "test@test.com\r"
expect  " admin password "
send    "test\r"
expect  " admin password again "
send    "test\r"
expect  "Done."
exit    0
EOF

