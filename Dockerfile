FROM centos:centos6
MAINTAINER kvaps <kvapss@gmail.com>
ENV SEAFILE_VERSION 5.0.2

RUN yum -y install tar epel-release
#Install Rspamd
RUN curl -L https://bintray.com/artifact/download/seafile-org/seafile/seafile-server_${SEAFILE_VERSION}_x86-64.tar.gz | tar xz -C /usr/src/

WORKDIR /usr/src/seafile-server-${SEAFILE_VERSION}

RUN yum -y upgrade
RUN yum -y install python-imaging MySQL-python python-simplejson python-setuptools which supervisor expect

ADD start.sh /bin/start.sh
ADD supervisord.conf /etc/supervisord.conf
ADD /wrappers/ /bin/
ENTRYPOINT ["/bin/start.sh"]

# Attach data volume
VOLUME ["/data"]

EXPOSE 8082 8000

