FROM debian:jessie

LABEL maintainer="service@biz-balance.de"

RUN apt-get update

# Common packages
RUN apt-get update && \
    apt-get install -y --force-yes curl wget

RUN apt-get update && \
    apt-get install -y --force-yes \
    	apache2 \
	exim4 \
	gcc \
	hunspell-de-de \
	imagemagick \
	libgpgme11-dev \
	libssh2-1-dev \
	lynx-cur \
	libapache2-mod-php5 \
	make \
	mcrypt \
	memcached \
	ntp \
        php5 \
	php5-cli \
        php5-curl \
	php5-dev \
	php5-enchant \
        php5-gd \
	php5-imagick \
	php5-imap \
        php5-mcrypt \
	php5-memcache \
        php5-mysql \
	php-pear \
	antiword \
	xpdf-utils \
	texlive-full \
        nano

RUN a2enmod \
        php5 \
        rewrite \
        ssl

RUN pecl install mailparse-2.1.6
RUN pecl install ssh2-beta
RUN pecl install gnupg

ENV APACHE_RUN_USER www-data
ENV APACHE_RUN_GROUP www-data
ENV APACHE_LOG_DIR /var/log/apache2
ENV APACHE_LOCK_DIR /var/lock/apache2
ENV APACHE_PID_FILE /var/run/apache2.pid

# Copy needed files
COPY	config/vhosts /etc/apache2/sites-enabled
COPY	config/ssl /etc/ssl
COPY	config/php /etc/php5/apache2/conf.d
COPY	config/root_bbCron.sh /root/bbCron.sh
COPY    config/cron /etc/cron.d/biz-balance
COPY    config/bb_cron_systems.bbcron /tmp/bb_cron_systems.bbcron

RUN chmod 755 /root/bbCron.sh

RUN mkdir -p /var/www/biz-balance

# expose Apache port to a network
EXPOSE 80
EXPOSE 443

ENTRYPOINT service cron start && service memcached start && service apache2 start && /bin/bash
