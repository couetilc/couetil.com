# Some notes on self-hosting Plausible.io

Running on a Digital Ocean droplet.

Set up `ufw`:

```
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow ssh
sudo ufw allow https
sudo ufw allow 60001 # mosh
```

Set up automatic updates:

```
sudo apt install unattended-upgrades
```

Set up `caddy`, `docker` and `plausible`:
- https://github.com/plausible/hosting/tree/master/reverse-proxy#no-existing-reverse-proxy
- https://docs.docker.com/engine/install/ubuntu/
- https://plausible.io/docs/self-hosting

To spin up the server, run:

```
docker-compose \
  -f compose/caddy.yml \
  -f compose/plausible.yml \
  -f compose/geoip.yml \
  up -d
```

