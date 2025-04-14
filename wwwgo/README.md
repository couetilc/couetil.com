# www

Go server powering the home page for my domain, [couetil.com](https://www.couetil.com).

TODO
- get other pages in here: (1) about (2) portfolio
- possible to include (1) time to serve request and (2) time since server boot in response?
- Dockerize this, so I can deploy an image on AWS Lambda. Resume will be a distinct build stage I pull the final files from.
- get resume page working


NOTE
- checkout `http/httptrace`, `http/httputil`, and `http/pprof` for robust web server. See what exactly they are used for.
