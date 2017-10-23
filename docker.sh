#!/bin/sh

docker run -d -v /data/mysql:/var/lib/mysql -v /data/log:/var/log/mysql -p 3306:3306 --name biz-balance_mysql  biz-balance/mysql

docker run -ti -d -p 2253:80 -v /var/www/html:/var/www/biz-balance --name biz-balance_apache biz-balance/apache /bin/bash