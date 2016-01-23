# Seafile in a docker

Quick start
-----------
Run command:

mysql:
```bash
docker run -d \
    -e MYSQL_ROOT_PASSWORD=<password> \
    --name seafile-db \
    -v /opt/seafile-db:/var/lib/mysql \
    mysql:5.5
```

seafile:
```bash
docker run -ti \
    -p 8082:8082 \
    -p 8000:8000 \
    --link seafile-db:seafile-db \
    --name seafile \
    -v /opt/seafile:/data \
    -e ADMIN_EMAIL=postmaster@example.org \
    -e ADMIN_PASSWD=<password> \
    -e MYSQL_ROOT_PASSWD=<password> \
     kvaps/seafile
```

Docker-compose
--------------

docker-compose.yml
```yaml
seafile:
  restart: always
  image: kvaps/seafile
  hostname: seafile
  domainname: example.org
  volumes:
    - /etc/localtime:/etc/localtime:ro
    - ./seafile:/data
  links:
    - seafile-db:seafile-db
  ports:
    - 8082:8082
    - 8000:8000
  environment:
    - ADMIN_EMAIL=postmaster@example.org
    - ADMIN_PASSWD=<password>
    - MYSQL_ROOT_PASSWD=<password>

seafile-db:
  restart: always
  image: mysql:5.5
  hostname: mysql
  volumes:
    - /etc/localtime:/etc/localtime:ro
    - ./mysql:/var/lib/mysql
  environment:
    - MYSQL_ROOT_PASSWORD=<password>
```

Multi-instances
---------------

I use [pipework](https://github.com/jpetazzo/pipework) script for passthrough external ethernet cards into docker container

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
            proxy_pass              http://10.10.10.124:8000/;
            proxy_set_header        Host            $host;
            proxy_set_header        X-Real-IP       $remote_addr;
            proxy_set_header        X-Forwarded-For $proxy_add_x_forwarded_for;
    }
    
    location /seafhttp {
            rewrite                 ^/seafhttp(.*)$ $1 break;
            proxy_pass              http://seafile-internal.BLARGH.com.au:8082;
            client_max_body_size    0;
            proxy_connect_timeout   36000s;
            proxy_read_timeout      36000s;
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
