# www

Go server powering the home page for my domain, [couetil.com](https://www.couetil.com).

TODO
- template partials for header, and meta tags, font preloads, the server time check, favicons, 
- is there any way to have go:embed flatten the filesystem for "templatesFS" and "staticFS"? So I don't have to prefix paths with "templates/" and "static/" in go code?
    - maybe instead of fs.FS object, it could be simple path of files, I think that's a go:embed option.
- possible to include (1) time to serve request and (2) time since server boot in response?
- Dockerize this, so I can deploy an image on AWS Lambda. Resume will be a distinct build stage I pull the final files from.
- get resume page working
- make a better 404 page
- make sure Go server is compressing all web pages and assets. It may be a `Transport` setting.


NOTE
- checkout `http/httptrace`, `http/httputil`, and `http/pprof` for robust web server. See what exactly they are used for.
