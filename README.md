# couetil.com

The code powering https://couetil.com

## Infrastructure

This website is current deployed on a Digital Ocean droplet "mangrove". It will
be replaced by a Cloudflare Worker CDN static thingamabob.

## Domain Name

The domain name is registered using Google Domains, and the nameservers
belong to Cloudflare, which manages DNS and other networking settings.

## Notes

# reference articles used for sentinel data download script

Useful article: https://medium.com/@anttilip/seeing-earth-from-space-from-raw-satellite-data-to-beautiful-high-resolution-images-feb522adfa3f
very useful: https://digital-geography.com/accessing-landsat-and-sentinel-2-on-amazon-web-services/

# if using Node.js to download these images

Node.js package: https://www.npmjs.com/package/gm

for using ImageMagic in Lambda function: https://serverlessrepo.aws.amazon.com/applications/arn:aws:serverlessrepo:us-east-1:145266761615:applications~image-magick-lambda-layer

check this out as a guide to optimizing the images using lambda: https://developer.happyr.com/aws-lambda-image-optimization-with-serverless
