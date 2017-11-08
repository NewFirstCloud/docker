#!/bin/sh

docker build -t biz_balance-mysql .

docker run -ti -d -p 3306:3306 -v /srv/mysql:/var/lib/mysql --name biz_balance-mysql biz_balance-mysql /bin/bash
