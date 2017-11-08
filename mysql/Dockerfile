FROM debian:jessie

LABEL maintainer="service@biz-balance.de"

#define access data
ENV DB_USER root
ENV DB_PASSWORD fc10KDTEST14
ENV DB_NAME bb_dev_0_0
ENV VOLUME_HOME "/var/lib/mysql"

# Get MySQL
RUN apt-get update
#RUN apt-get install -y mysql-server-5.5
RUN apt-get update \
    && apt-get install -y debconf-utils \
    && echo mysql-server-5.5 mysql-server/root_password password ${DB_PASSWORD} | debconf-set-selections \
    && echo mysql-server-5.5 mysql-server/root_password_again password ${DB_PASSWORD} | debconf-set-selections \
    && apt-get install -y mysql-server-5.5 -o pkg::Options::="--force-confdef" -o pkg::Options::="--force-confold" --fix-missing \
    && rm -rf /var/lib/apt/lists/*

# Remove pre-installed database
RUN rm -rf /var/lib/mysql/*

# Open MySQL to a world
RUN sed -i -e"s/^bind-addresss*=s*127.0.0.1/bind-address = 0.0.0.0/" /etc/mysql/my.cnf

# Script to pass MySQL
ADD startup.sh /
RUN chmod 755 /*.sh

# expose MySQL port to a network
EXPOSE 3306

# open to mount
# VOLUME ["/var/lib/mysql", "/var/log/mysql"]

# start container
CMD ["/bin/bash", "/startup.sh"]
