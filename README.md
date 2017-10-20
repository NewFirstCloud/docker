# docker for biz-balance

Stellt eine Docker-Umgebung zum Betrieb von biz-balance bereit.

```bash
> docker build -t apache22php53 .

> docker run -ti -d -p 2253:80 -v /var/www/html:/var/www/biz-balance --name biz-balance apache22php53 /bin/bash
> docker exec -ti biz-balance /bin/bash
> docker container ls

```
