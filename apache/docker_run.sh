#!/bin/sh

docker build -t biz_balance-apache .

docker run -ti -d -p 80:80 -p 443:443 -v /srv/www:/var/www/biz-balance --name biz_balance-apache biz_balance-apache /bin/bash
