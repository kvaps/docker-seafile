# docker-seafile

docker run -d -p 3306:3306 -e MYSQL_ROOT_PASSWORD=seafile -e MYSQL_DATABASE=seafile -e MYSQL_USER=seafile -e MYSQL_PASSWORD=seafile --name seafile-db mysql:latest

docker run -ti -p 8082:8082 -p 8000:8000 --link seafile-db --rm --name seafile --entrypoint=/bin/bash kvaps/seafile
