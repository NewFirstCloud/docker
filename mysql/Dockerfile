FROM debian:jessie

LABEL maintainer="service@biz-balance.de"
 
# Get MySQL
RUN apt-get update
RUN apt-get install -y mysql-server-5.5
 
# Remove pre-installed database
RUN rm -rf /var/lib/mysql/*
 
# Open MySQL to a world
RUN sed -i -e"s/^bind-addresss*=s*127.0.0.1/bind-address = 0.0.0.0/" /etc/mysql/my.cnf
 
# Script to pass MySQL
ADD startup.sh /
RUN chmod 755 /*.sh
 
#define access data
ENV DB_USER docker_user
ENV DB_PASSWORD 1234
ENV DB_NAME wordpress
ENV VOLUME_HOME "/var/lib/mysql"
 
# expose MySQL port to a network
EXPOSE 3306
 
# open to mount
# VOLUME ["/var/lib/mysql", "/var/log/mysql"]
 
# start container
CMD ["/bin/bash", "/startup.sh"]
