# Seafile in a docker

Run command
-----------

```bash
docker run -d -e MYSQL_ROOT_PASSWORD=<password> --name seafile-db -v /opt/seafile-db:/var/lib/mysql mysql:5.5
```

```bash
docker run -ti -p 8082:8082 -p 8000:8000 --link seafile-db:seafile-db --name seafile -v /opt/seafile:/data-e ADMIN_EMAIL=postmaster@example.org -e ADMIN_PASSWD=<password> -e MYSQL_ROOT_PASSWD=<password>  kvaps/seafile
```

Multi-instances
---------------

I use [pipework](https://github.com/jpetazzo/pipework) script for passthrough external ethernet cards into docker container

I write such systemd-unit:
```bash
vi /etc/systemd/system/seafile@.service
```
```ini
[Unit]
Description=Seafile for %I
After=docker.service
Requires=docker.service

[Service]
EnvironmentFile=/etc/seafile-docker/%i
Restart=always

ExecStart=/bin/bash -c ' \
        /usr/bin/docker run -d -v ${DOCKER_MYSQL_VOLUME}:/var/lib/mysql --name ${DOCKER_MYSQL_NAME} mysql:5.5 && \
        /usr/bin/docker run -p 8082:8082 -p 8000:8000 --link ${DOCKER_MYSQL_NAME}:seafile-db --name ${DOCKER_SEAFILE_NAME} -v ${DOCKER_SEAFILE_VOLUME}:/data ${DOCKER_OPTIONS} kvaps/seafile'
ExecStartPost=/bin/bash -c ' \
        until [ "`/usr/bin/docker inspect -f {{.State.Running}} ${DOCKER_SEAFILE_NAME}`" == "true" ]; do sleep 0.1; done; \
        pipework ${EXT_INTERFACE} -i eth1 ${DOCKER_SEAFILE_NAME} ${EXT_ADDRESS}@${EXT_GATEWAY}; \
        docker exec ${DOCKER_SEAFILE_NAME} bash -c "${INT_ROUTE}"; \
        docker exec ${DOCKER_SEAFILE_NAME} bash -c "if ! [ \"${DNS_SERVER}\" = \"\" ] ; then echo nameserver ${DNS_SERVER} > /etc/resolv.conf ; fi" '
ExecStop=/bin/bash -c '/usr/bin/docker stop -t 2 ${DOCKER_SEAFILE_NAME} ${DOCKER_MYSQL_NAME} ; docker rm -f ${DOCKER_SEAFILE_NAME} ${DOCKER_MYSQL_NAME}'

[Install]
WantedBy=multi-user.target
```

And this config for each instance:
```bash
vi /etc/seafile-docker/example.org
```
```bash
DOCKER_HOSTNAME="cloud.example.org"
DOCKER_MYSQL_NAME="seafile-db-$(echo $DOCKER_HOSTNAME | cut -d. -f 2-)"
DOCKER_SEAFILE_NAME="seafile-$(echo $DOCKER_HOSTNAME | cut -d. -f 2-)"
DOCKER_MYSQL_VOLUME="/opt/seafile-$(echo $DOCKER_HOSTNAME | cut -d. -f 2-)/mysql"
DOCKER_SEAFILE_VOLUME="/opt/seafile-$(echo $DOCKER_HOSTNAME | cut -d. -f 2-)/seafile"
DOCKER_OPTIONS='-e ADMIN_EMAIL=postmaster@example.org -e ADMIN_PASSWD=yKdU6VdeFr8MgqQ -e MYSQL_ROOT_PASSWD=WPvFwHjkcqcF2bfy5fDW'

EXT_INTERFACE=eth2
EXT_ADDRESS='10.10.10.124/24'
EXT_GATEWAY='10.10.10.1'
DNS_SERVER='8.8.8.8'

INT_ROUTE='ip route add 192.168.1.0/24 via 172.17.42.1 dev eth0'

```
Just simple use:
```bash
systemctl enable seafile@example.org
systemctl start seafile@example.org
```

Kolab instance integration
--------------------------
You can integrate seafile with my [kolab](https://github.com/kvaps/docker-kolab) docker image

Just follow these simple steps:

Create nginx config for seafile proxing in kolab container.

vi /opt/kolab-example.org/etc/nginx/conf.d/seafile.conf

```nginx
server {
    listen 80 default;
    server_name  example.org;
    server_name_in_redirect off;
    rewrite ^ https://$http_host$request_uri permanent; # enforce https redirect
}


server {
    listen 443 ssl default;
    server_name  example.org;

    ssl on;
    ssl_certificate /etc/pki/tls/certs/mail.example.org.crt;
    ssl_certificate_key /etc/pki/tls/private/mail.example.org.key;
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains";

    client_max_body_size 5g;

    location / {
            proxy_redirect off;
            proxy_buffering off;
            proxy_set_header        Host                    $host;
            proxy_set_header        Destination             $http_destination;
            proxy_set_header        X-Real-IP               $remote_addr;
            proxy_set_header        X-Forwarded-For         $proxy_add_x_forwarded_for;
            proxy_set_header        X-Forwarded-Proto       $scheme;
            add_header              Front-End-Https         on;
            proxy_pass              http://10.10.10.124:8000/;
    }
}
```

Next folow [this instruction](https://docs.kolab.org/howtos/use-seafile-with-chwala.html):

vi /opt/kolab-example.org/etc/roundcubemail/config.inc.php
```php
# Force https redirect for http requests
$config['force_https'] = true;
# Seafile
$config['fileapi_backend'] = 'seafile';
$config['fileapi_seafile_host'] = "localhost";
$config['fileapi_seafile_ssl_verify_peer'] = false;
$config['fileapi_seafile_ssl_verify_host'] = false;
# Change the following basing on how much time you want data from Seafile cached
$config['fileapi_seafile_cache'] = '14d';
$config['fileapi_seafile_debug'] = true;
```

vi /opt/seafile-example.org/seafile/conf/ccnet.conf
```ini
[LDAP]
HOST = ldap://10.10.10.123
# Change the following to your primary domain base DN
BASE = ou=People,dc=example,dc=org
FILTER = &(objectclass=kolabinetorgperson)
# Put in the details of the Kolab service account
USER_DN = uid=kolab-service,ou=Special Users,dc=example,dc=org
PASSWORD = <password>
LOGIN_ATTR = mail
```
