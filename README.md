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

## Notes

# reference articles used for sentinel data download script

Useful article: https://medium.com/@anttilip/seeing-earth-from-space-from-raw-satellite-data-to-beautiful-high-resolution-images-feb522adfa3f
very useful: https://digital-geography.com/accessing-landsat-and-sentinel-2-on-amazon-web-services/

# if using Node.js to download these images

Node.js package: https://www.npmjs.com/package/gm

for using ImageMagic in Lambda function: https://serverlessrepo.aws.amazon.com/applications/arn:aws:serverlessrepo:us-east-1:145266761615:applications~image-magick-lambda-layer

check this out as a guide to optimizing the images using lambda: https://developer.happyr.com/aws-lambda-image-optimization-with-serverless

## TODO

- add step to github action that invalidates cloudfront cache, and test with a
  deploy. Also determine if will need to add cloudflare cache invalidation call.
- download fonts from Google Fonts to this repo and deploy
- add a 404 or error page for users (or just add a JSON { error: 404 }) in cloudfront
  and s3, so errors and missing pages have a non-AWS response.
- add links to github, resume, etc.
- when uploading to GitHub, add cache headers so TTL is 1 week
- self host plausible from raspberry pi using my domain? https://plausible.io/docs/self-hosting.
  could also host plausible using sandstorm? https://sandstorm.io/instal
  (install this anyway on PI and check out the apps) sandstorm may not be
  worked on anymore, try homelabOS? https://homelabos.com/
- check out budget.json see https://web.dev/use-lighthouse-for-performance-budgets/
- on mobile, stack "CONNOR" on top of "COUETIL" and make both words the same width, no more both words on same line
- I might want to separate out the 2x images into separate <code><picture></code>
  elements, for some reason chrome requests and downloads both the 1x and 2x satellite images
- dark mode, add a toggle in the top right of the page, and also check
  the system setting
- different images during the day vs. at night, or do it based on Dark Mode
- github action that takes screenshots of the website when a PR is made against
  it? Using this: https://htmlcsstoimage.com/
