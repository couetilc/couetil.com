# www

Go server powering the home page for my domain, [couetil.com](https://www.couetil.com).

TODO
- Do I need something like CloudInit for the AWS Linux VM image? to do system configuration? For example, to harden SSH using this as guide https://infosec.mozilla.org/guidelines/openssh?
- Hashing the assets may require some "build tool" e.g. `go build -a -toolexec "yourtool someargs"`
    - I want to use FNV-1a to hash the file. Fast, randomly distributed, unlikely to collide.
    - see https://www.youtube.com/watch?v=5l-W7vPSbuc
    - maybe `go generate`
    - I think the best approach, is just to load into binary with go:embed, and then hash into a map on startup, insert hashed filenames into HTML, and then when requests for assets come through, match the hash string to the embedded asset. This way, go:embed is fine and no need for odd build tools or plugins, but I will need to hack the fileserver to somehow match hashed filenames to the asset. I guess I could do that simply by stripping the hashkey from the URL. Client's and upstream CDNs will use the hash to cache, and I will use the filename to serve. Actually, does it have to be in the URL then should it just be a Header? I think caching by URL is more universal and supported by web browsers however.
	- e.g. [go:embed] static/myimage.jpeg -> [internally produce hash and serve] static/myimage-12345.jpeg -> [request comes in for] static/myimage-12345.jpeg -> [before fileserver I strip the hash] static/myimage.jpeg -> [serve the image data]
	- URLs will always cause a cache-hit to miss, and the browser to check for new resources, that's a thing.
	- If I get a hashkey from a client, and its not in my map, it must be a reference to an old resource somehow. I need to 404 that hashkey instead of stripping it and serving the new asset. So there will need to be a hash validation step before the strip and serve step.
	- Need to explore what cache-headers I need.
	    - ETags are a must. Need to explore more. They are for when content has expired, and are a cheap method of revalidation from the server for the browser. I will need to implement proper server 304 Not Modified responses for these type of asset requests from a CDN or browser (e.g. If-Match or If-None-Match)
	    - Those ETags will be primarily for my HTML pages.
	- Hashed static content will use immutable Cache-Control directive. It doesn't work on every browser, so I can also set max-age to be very long, like a year.
- Remember, have cloudfront compress everything. Normal responses from Go server and API gateway.
- Get cache headers working and set up API Gateway. Etags or Cache TTL? Would want to do it by adding cache strings to assets
- get resume page working
    - will be a distinct build stage I pull the .pdf, .html, and .css from
- combine all the CSS into one file?
- make a better 404 page. I think I have black text on black background right now
- make sure Go server is compressing all web pages and assets. It may be a `Transport` setting.
- can I create hashed asset files? What would look like? Would need a helper function for templates that refer to an internal map of assets
- instead of listing documentation here like in available layouts, and template context, is there a Go documentation convention, like godocs, or python `"""` docstrings, that I can use instead? And build a docs folder programmatically?
- security? security headers? Disallow any IP access unless its AWS only? Traffic only through cloudfront and api gateway?
- Benchmarking
    - can I test how much memory is best for this? or establish diminishing returns? by using docker container features to limit memory accessible by running container then benchmarking against
        - this is a synthetic test that does not account for AWS infrastructure
        - Is there a way I can measure _actual_ CPU usage of the go process in the container? Regardless of how much it's _allowed_ to use? 
    - Apparently there can be a lot of CPU throttling for smaller lambda functions
        - run a benchmark against a matrix of deployed lambda after I run my above tests. If above tests do not use memory above 128MB (smallest lambda size) it won't matter.
- Set up monitoring and billing dashboards using service tags.
- establish some way to monitor cache hits, to see if I need origin shield.
- Go through "Root User best practices for AWS account" to secure login https://docs.aws.amazon.com/IAM/latest/UserGuide/root-user-best-practices.html
- May want to switch DNS name servers for couetil.com to Route53
- my origin protocol policy is HTTP only right now. That's fine, because its static files, but is all traffic from cloudfront->api_gateway->lambda going through VPC? It needs to be internet->cloudfront->[vpc|api_gateway->lambda]
- It would be fun to publish a benchmark of these hash functions on different hardware, with different filetypes (code vs images vs english language), and different algorithms. Would be a nice reference for Go programs. And a good first blog post for my blog.
    - Use this stack overflow answer as a good reference for how to display the results of the benchmark https://softwareengineering.stackexchange.com/questions/49550/which-hashing-algorithm-is-best-for-uniqueness-and-speed
    - Just use the hash functions from the standard library: [hash] adler32, crc32, crc64, fnv, maphash, [crypto] 
    - split out results between hash focused and crypto focused. Compare memory usage not just speed. Have single threaded vs multi-threaded too.
    - use AWS spot instances in order to reduce the price of running these benchmarks. Basically, if a new hash version comes out, schedule a benchmark run, and wait for spot instances to get cheap. (need to make sure either EBS instances are deleted and removed, or not used at all. Better if not used so test runs in memory? IDK)

NOTE
- checkout `http/httptrace`, `http/httputil`, and `http/pprof` for robust web server. See what exactly they are used for.
- was ~135MB before with lambda OS image and base go for web server. What is it with lambda adapter and aws packages?

## Development

Install:
- `direnv`
- Docker
- Go
- `terraform`

See `bin/` for commands.

## Architecture

AWS API Gateway invokes this Lambda function. Fronted by Cloudfront

Cloudfront -> API Gateway -> AWS Lambda

What about using "Lambda@Edge" and "Edge Optimized API Gateway"?
(Lambda@Edge is 3x more expensive)

If using Lambda@Edge to generate HTTP Response for Cloudfront, use this approach: https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/lambda-generating-http-responses.html#lambda-generating-http-responses-in-requests
- Will use event trigger for "Origin Request", so that response is cached.

Would be fun to test the cold start and latency differences for 
- Cloudfront -> API Gateway -> AWS Lambda
- Cloudfront -> Lambda@Edge

I will first do typical CF -> APIG -> Lambda, then I will do CF -> Lambda@Edge and compare.

## HTML template convention

All Go template files will be stored in the directory `templates/` with the
file suffix `.tmpl`. There is a convention for naming templates, which
influences how they are utilized. Templates prefixed with `layout_` (layouts)
or `partial_` (partials) are pre-loaded and available for use with the
[template action "template"](#todo-link-to-godocs) in a regular template. A
regular template can be invoked by an HTTP handler specified in the
[`NewServer` function](#todo-link-to-main.go:NewServer). Layouts are HTML
document skeletons that should expose blocks that can be overriden by a regular
template and are expected to be used once. Partials do not layout an HTML
document and may be re-used.

### Template Context

Each template receives a context object. Currently, the context shape is

```go
type TemplateContext struct {
	time.Time
	*url.URL
}
```

### Available Layouts

Documentation for the available layouts.

#### `layout_default.tmpl`

Pre-loads fonts, loads common stylesheet, and exposes three blocks: `"title"`,
`"head"`, and `"body"`.
