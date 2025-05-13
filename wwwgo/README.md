# www

Go server powering the home page for my domain, [couetil.com](https://www.couetil.com).

PASSWORD Management:
- currently I'm using SOPS and a secrets.yaml file for secret management
- 1password's `op` command line tool has a command, `op run`, which will
  resolve any environment variables that are `op://` URIs to the value.
    - Then I won't need that KMS key anymore, less money per month, good idea
      here. And my project dependency switches from SOPS to `op`. But, how will
      I decrypt secrets on the server? Maybe I don't need to, I can bake it
      into an image, or send commands over an SSH session. OK, let's try it.
      Then commands in `bin/` can be prefixed with `op run -- <command>`
      whenever I need a secret from the environment.
	- I can also make it prod/dev environment specific, see `op run -h`
	```
	DB_USERNAME = op://$APP_ENV/db/username
	DB_PASSWORD = op://$APP_ENV/db/password
	# now I can 
	export APP_ENV="dev"
	# or
	export APP_ENV="prod"
	# and `op run` will resolve the DB_* according to APP_ENV
	```
	- And can inject into files using `{{ op://* }}` syntax!

WIREGUARD Management
- I need to generate:
    - a wireguard client configuration that will fetch dynamic data like:
	- public ip of VM wireguard server is running on
	- Public key of wireguard server
	- Private Key of wireguard client
    - a wireguard server configuration that will fetch dynamic data like:
	- private key of wireguard server
	- public key of wireguard client
- what does the lifecycle of this look like?
    - for the server:
	- baked into VM image with Packer
	- do I want to allow updating this at VM runtime? IDK
	    - wouldn't be super hard, but I would need to create a script in bin/ that does this e.g. `.wg-rotate`
    - for the client
	- hopefully using direnv lifecycle, I can write into a temporary folder for the lifetime of the session
	- e.g.
	    - cd into directory
		- configuration file is generating and written into temp/hidden folder
		- wireguard interface is brought up
	    - cd out of directory
		- wireguard interface is brought down
		- temporary/hidden directory is cleaned up
- I can't exactly use direnv here, because wireguard is a system-wide service
  and direnv is per-shell env/path management, so I will just have to have
  scripts that check my "www.couetil.com" wireguard interface is up, and if
  not, spin it up before connecting to the server. I will have those scripts
  write a config file to the right place too, and have a script to update the
  conf file whenever I update the secrets.
    - e.g.
	- `bin/.connect`: `./vpn up` -> ssh to box using wg IP
	- `bin/.vpn client-up`: script to open wg interface (if not already up) -> writes conf file for client -> wg-quick up
	- `bin/.vpn client-down`: script to close wg interface (if not already down) -> wg-quick down -> removes conf file for client
    - I think I need a name for this interface that is not "wg0"? "vpn.couetil.com"? "www.wg0"? (limited to 1-15 characters, pattern is "[a-zA-Z0-9_=+.-]{1,15}"

SYSTEMD SETUP
- Go through these
    - https://mgdm.net/weblog/systemd/
    - https://mgdm.net/weblog/systemd-socket-activation/
    - great stuff in here, like systemd options for security. (e.g. run `sudo systemd-analyze security www.service --no-pager`), making sure to create a user for the service with limited privileges dynamically that is removed when the service stops, etc.)
- this article explains graceful shutdown https://vincent.bernat.ch/en/blog/2018-systemd-golang-socket-activation and zero-downtime deploy
- this has an example go server with zero downtime, graceful shutdowns, and systemd stuff, more complex and full than others https://gist.github.com/rsms/b70b4c7fe3b25e17b4b1f6af8b007c14

NEW ARTCHITECTURE
- OK, just AWS Cloudfront, and cheapest EC2, in default public subnet.
- Security will be non-default SSH port, non-default HTTP port, and restrict SSH access to USA IPs, and WireGuard tunnel needed for any SSH access (but how to include that in security group rules?), SSH access only from wireguard local ip address, and restrict access to HTTP to cloudfront only. (also, should I lock down outgoing traffic? it kind of makes sense but what about downloading software updates and certificate updates? I guess just allow access to those repositories.)
- use cloud init to define EC2 base image, including wireguard private key.
- should I just log to filesystem? rather than s3? and use a cli based log search over SSH? and what about alerting? and I'll need a log of failed network requests on the instance. I need to get logs for all running processes basically.
- network logging with iptables. Need to learn to configure iptables.
- Use PyInfra with Cloud-Init, no ansible? Cloud-init will configure the VM from start, and PyInfra will make sure configuration drift can be fixed or changed on the fly. So I can CLoud-Init hte VM to make sure all the dependencies are available and users are set up, then run PyInfra for a final baked config based on those dependencies and users.. For example, CLoud-init can set up the SSH keys and then PyInfra can use those keys to communicate after spin-up.

VM network traffic flow
```
WireGuard --> SSH
Cloudfront --> HAProxy
HAProxy --> Www
```

can put wireguard IP addresses for VPN clients (laptop, vm) in .envrc in a project-specific way. then in ssh config give them a name. wireguard configs will live in the repo.

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
