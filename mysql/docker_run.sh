#!/bin/sh

docker build -t biz_balance-mysql .

docker run -ti -d -p 3306:3306 -p 443:443 -p 80:80 -v /srv/mysql:/var/lib/mysql -v /srv/www:/var/www --name biz_balance-mysql biz_balance-mysql /bin/bash
