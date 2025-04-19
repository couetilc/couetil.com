# www

Go server powering the home page for my domain, [couetil.com](https://www.couetil.com).

TODO
- any public ingress into my software resources MUST be from Cloudfront. I need to lockdown my API gateway from public access. Then I need to make sure APIG and Lambda in same VPC and region and Availability Zone?
    - I'll have to disable the default_endpoint setting once I have the connection to cloudfront going, I guess.
    - I think I'll have to create a VPC link to the lambda function, and then the cloudfront distribution.
- Hashing the assets may require some "build tool" e.g. `go build -a -toolexec "yourtool someargs"`
    - see https://www.youtube.com/watch?v=5l-W7vPSbuc
    - maybe `go generate`
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

NOTE
- checkout `http/httptrace`, `http/httputil`, and `http/pprof` for robust web server. See what exactly they are used for.
- was ~135MB before with lambda OS image and base go for web server. What is it with lambda adapter and aws packages?

## Development

Install:
- `direnv`
- Docker
- Go

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
