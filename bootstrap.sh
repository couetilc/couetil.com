#!/usr/bin/env bash
sops exec-file --no-fifo --output-type dotenv secrets.yml 'docker-compose --env-file {} -f compose/caddy.yml -f compose/plausible.yml -f compose/geoip.yml up -d'
