# docker installieren

```bash
> apt-get install apt-transport-https ca-certificates curl gnupg2 software-properties-common
> curl -fsSL https://download.docker.com/linux/$(. /etc/os-release; echo "$ID")/gpg | sudo apt-key add -
> add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/$(. /etc/os-release; echo "$ID") $(lsb_release -cs) stable"
> apt-get update
> apt-get install docker-ce
> systemctl start docker
> systemctl enable docker
```

# docker-compose installieren

```bash
> curl -L https://github.com/docker/compose/releases/download/1.17.0/docker-compose-`uname -s`-`uname -m` -o /usr/local/bin/docker-compose
> chmod +x /usr/local/bin/docker-compose
> docker-compose --version
```

# biz-balance vorbereiten

- Datenbank-Tabelle `system_statistik` truncaten.
- Datenbank-Dump erstellen und in `/srv/mysql/` bereitstellen.
- biz-balance Dateien in das Verzeichnis `/srv/www/` kopieren.
- in der Datei `./apache/config/bb_cron_systems.bbcron` den Datenbank-Namen `bb_dev_0_0` durch den richtigen Namen ersetzen.
- in der Datei `./mysql/Dockerfile` den Datenbank-Namen, den -Benutzer und das -Passwort ersetzten. Wichtig: Datenbank-Benutzer ist __nicht__ `root`, sondern `bb_<name>` 
- neue Zertifikate im Verzeichnis `./apache/config/ssl/` erstellen oder durch eigene Zertifikate ersetzen.
- ggf. Verzeichnisrechte der `/srv/`-Verzeichnisse anpassen.
- `mandaten.stg` mit den neuen Daten erstellen und austauschen.
- in der `config.inc` den Pfad für das `ROOT_DIR` auf `/var/www/biz-balance/` korrigieren.
- `docker.sh` ausführen
- den Container `docker_biz_balance-mysql_1` per Shell öffnen.
- den Datenbank-Dump einspielen (ggf. `dpkg-reconfigure mysql-server-5.5` auf dem Container durchführen, wenn der Zugriff verweigert wird).
- Datenbanktabelle `cron_jobs_x_server` leeren: `TRUNCATE `cron_jobs_x_server`;`
- biz-balance testen: Cronjobs, PDF-Generierung (alt / neu), E-Mail senden (inkl. Anhänge) / empfangen.
- anschließend das Verzeichnis `.git` und den Bereich `biz-balance vorbereiten` aus der `README.md` löschen 

```bash
> openssl genrsa -out ./apache/config/ssl/biz_balance.key 2048
> openssl req -new -key ./apache/config/ssl/biz_balance.key -out ./apache/config/ssl/biz_balance.csr
> openssl x509 -req -days 3650 -in ./apache/config/ssl/biz_balance.csr -signkey ./apache/config/ssl/biz_balance.key -out ./apache/config/ssl/biz_balance.crt
> cat ./apache/config/ssl/biz_balance.crt ./apache/config/ssl/biz_balance.key > ./apache/config/ssl/biz_balance.pem
```

Datenbank von Statistiken bereinigen:
```bash
> mysql -uroot -p
> use bb_dev_0_0;
> TRUNCATE system_statistik;
> TRUNCATE system_statistik_categories;

```

Datenbank-Dump erstellen:
```bash
> mysqldump -h localhost -u root -p -c --databases bb_dev_0_0 --skip-opt --add-drop-table --add-locks --create-options --quick --quote-names --result-file=./bb_dev_0_0.sql
> gzip ./bb_dev_0_0.sql
> scp ./bb_dev_0_0.sql.gz root@192.0.0.2:/srv/mysql/
> gunzip ./bb_dev_0_0.sql.gz
> mysql -u root --default-character-set=utf8 bb_dev_0_0 < /var/lib/mysql/bb_dev_0_0.sql
```

```bash
> rsync --stats --progress --exclude=profiles --exclude=tmp -r -l -H -z /srv/saas_agency/ root@192.0.0.2:/srv/www/
> rsync --stats --progress -r -l -H -z /srv/profiles/bb_dev_0_0 root@192.0.0.2:/srv/www/profiles/
```

# docker for biz-balance

Stellt eine Docker-Umgebung zum Betrieb von biz-balance bereit.

```bash
> docker.sh
```

Runterfahren:

```bash
> docker-compose down
```

In die Shell des Containers wechseln:

```bash
> docker exec -it docker_biz_balance-apache_1 bash
> docker exec -it docker_biz_balance-mysql_1 bash
```

Neue Zertifikate erstellen:

```bash
> openssl genrsa -out biz_balance.key 2048
> openssl req -new -key biz_balance.key -out biz_balance.csr
> openssl x509 -req -days 3650 -in biz_balance.csr -signkey biz_balance.key -out biz_balance.pem
```
