# couetil.com

The code powering https://couetil.com

## Development

To start a development server with [snowpack](https://github.com/snowpackjs/snowpack):
```sh
npm start
```

To build for production:
```sh
npm run build
```

## Deployment

To deploy to production at https://couetil.com (and https://www.couetil.com and
https://connor.couetil.com), push a new tag `vYYYY.MM.DD.##` to the project's
[GitHub Repository](https://github.com/couetilc/couetil.com), where `YYYY` is
current year, `MM` the month, `DD` the day, and `##` the number of releases
that day. A GitHub [Action](https://github.com/couetilc/couetil.com/blob/master/.github/workflows/build_test_deploy.yml)
will then deploy the website.

## Infrastructure

Website files are stored on a [Digital Ocean](http://digitalocean.com/) droplet
and services are managed by [Docker Compose](https://docs.docker.com/compose/).
[Caddy](https://caddyserver.com/) acts as a file server and reverse proxy.

## Domain Name

The domain name is registered using Google Domains, and the nameservers
belong to Cloudflare, which manages DNS and other networking settings.
