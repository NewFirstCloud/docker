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

# docker for biz-balance

Stellt eine Docker-Umgebung zum Betrieb von biz-balance bereit.

```bash
> docker.sh
```

Runterfahren:

```bash
> docker-compose down
```
