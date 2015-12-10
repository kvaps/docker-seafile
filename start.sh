#!/bin/bash

random_pwd()
{
        cat /dev/urandom | env LC_CTYPE=C tr -dc a-zA-Z0-9 | head -c 16; echo;
}

generate_dn()
{
    echo $(hostname -d) | sed 's/^/dc=/g' | sed 's/[\.]/,dc=/g'
}

chk_var () {
   var=$(sh -c "echo $(echo \$$1)")
   [ -z "$var" ] && export "$1"="$2"
}

load_defaults()
{
    chk_var  TZ                    "utc"
    chk_var  SERVER_NAME           "seafile"
    chk_var  SERVER_HOSTNAME       "seafile"
    chk_var  SEAFILE_DATA          "/data/seafile-data"
    chk_var  SEAHUB_PORT           "8082"
    chk_var  MYSQL_CREATE_DB       1
#   chk_var  MYSQL_ROOT_PASSWD     ""
    chk_var  MYSQL_HOSTNAME        "seafile-db"
    chk_var  MYSQL_PORT            "3306"
    chk_var  MYSQL_USER            "seafile"
#    chk_var  MYSQL_PASSWD          ""
    chk_var  MYSQL_CCNET_DBNAME    "ccnet-db"
    chk_var  MYSQL_SEAFILE_DBNAME  "seafile-db"
    chk_var  MYSQL_SEAHUB_DBNAME   "seahub-db"
#    chk_var  ADMIN_EMAIL           "test@example.org"
#    chk_var  ADMIN_PASSWD          `random_pwd`
}

set_timezone()
{
    if [ -f /usr/share/zoneinfo/$TZ ]; then 
        rm -f /etc/localtime && ln -s /usr/share/zoneinfo/$TZ /etc/localtime
    fi
}

move_dirs()
{
    echo "info:  start moving Seafile folders"
    cp -rax /usr/src/seafile-server-*/ /data/seafile/
    echo "info:  finished moving Seafile folders"
}

configure_seafile()
{
    echo "info:  start configuring Seafile"

    [ -z "$ADMIN_EMAIL" ] && echo "err:   \$ADMIN_EMAIL is not set" ; exit 1
    [ -z "$ADMIN_PASSWD" ] && echo "err:   \$ADMIN_PASSWD is not set" ; exit 1

    IFS='' 
    
    first_step=$(cat<<EOF
spawn   ./setup-seafile-mysql.sh
set timeout 300
expect  "Press ENTER to continue"
send    "\r"
expect  " server name "
send    "${SERVER_NAME}\r"
expect  " This server's ip or domain "
send    "${SERVER_HOSTNAME}\r"
expect  " default "
send    "${SEAFILE_DATA}\r"
expect  " default \"8082\" "
send    "${SEAHUB_PORT}\r"
expect  " 1 or 2 "
send    "${MYSQL_CREATE_DB}\r"
expect  " default \"localhost\" "
send    "${MYSQL_HOSTNAME}\r"
expect  " default \"3306\" "
send    "${MYSQL_PORT}\r"
expect  " mysql user for seafile "
EOF
    )

    if [ "$MYSQL_CREATE_DB" = "1" ]; then

        [ -z "$MYSQL_ROOT_PASSWD" ] && echo "err:   \$MYSQL_ROOT_PASSWD is not set" ; exit 1
        second_step=$(cat<<EOF

expect  " root password "
send    "${MYSQL_ROOT_PASSWD}\r"
expect  " default \"root\" "
send    "${MYSQL_USER}\r"
EOF
    )

        if [ "$MYSQL_USER" != "root"]; then

        [ -z "$MYSQL_PASSWD" ] && echo "err:   \$MYSQL_PASSWD is not set" ; exit 1
            third_step=$(cat<<EOF

expect  " password for * "
send    "${MYSQL_PASSWD}\r"
EOF
            )
        fi

    elif [ "$MYSQL_CREATE_DB" = "2" ]; then

        [ -z "$MYSQL_PASSWD" ] && echo "err:   \$MYSQL_PASSWD is not set" ; exit 1
        second_step=$(cat<<EOF

send    "${MYSQL_USER}\r"
expect  " password for * "
send    "${MYSQL_PASSWD}\r"
expect  " ccnet database "
EOF
    )
    fi

    final_step=$(cat<<EOF

send    "${MYSQL_CCNET_DBNAME}\r"
expect  " seafile database "
send    "${MYSQL_SEAFILE_DBNAME}\r"
expect  " seahub database "
send    "${MYSQL_SEAHUB_DBNAME}\r"
expect  "Press ENTER to continue"
send    "\r"
expect  "Your seafile server configuration has been finished successfully."
exit    0
EOF
    )
    echo $first_step $second_step $third_step $final_step #| expect

    unset IFS
    ./seafile.sh start

    expect <<EOF
spawn   ./seahub.sh start
set timeout 300
expect  " admin email "
send    "${ADMIN_EMAIL}\r"
expect  " admin password "
send    "${ADMIN_PASSWD}\r"
expect  " admin password again "
send    "${ADMIN_PASSWD}\r"
expect  "Done."
exit    0
EOF
    ./seafile.sh stop
    ./seafile.sh stop


    echo "info:  finished configuring Seafile"
}

start_services()
{
             echo "info:  Starting services"
                      /usr/bin/supervisord
} 

[ ! -d /data/seafile ] && export FIRST_SETUP=true #Check for first setup

                                load_defaults
                                set_timezone
if [ "$FIRST_SETUP" = true ] ; then
                                move_dirs
                                configure_seafile
fi
                                start_services
