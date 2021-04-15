# couetil.com

The code powering https://couetil.com

## Development

To start a development server with snowpack:
```sh
npm start
```

To build for production:
```sh
npm run build
```

## Deployment

To deploy to production at https://couetil.com (and https://www.couetil.com and
https://connor.couetil.com), push your changes to the `master` branch in the
project's [GitHub Repository](https://github.com/couetilc/couetil.com). A
GitHub Action will then deploy the website.

## Infrastructure

Website files are stored on an S3 bucket "couetil.com" under the "www" prefix.
A Cloudfront distribution sits in front of the S3 bucket.

## Domain Name

The domain name is registered using Google Domains, and the nameservers
belong to Cloudflare, which manages DNS and other networking settings.
