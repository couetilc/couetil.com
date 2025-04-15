# www

Go server powering the home page for my domain, [couetil.com](https://www.couetil.com).

TODO
- Dockerize this, so I can deploy an image on AWS Lambda. Resume will be a distinct build stage I pull the final files from.
- get resume page working
- combine all the CSS into one file?
- make a better 404 page
- make sure Go server is compressing all web pages and assets. It may be a `Transport` setting.
- can I create hashed asset files? What would look like? Would need a helper function for templates that refer to an internal map of assets
- instead of listing documentation here like in available layouts, and template context, is there a Go documentation convention, like godocs, or python `"""` docstrings, that I can use instead? And build a docs folder programmatically?


NOTE
- checkout `http/httptrace`, `http/httputil`, and `http/pprof` for robust web server. See what exactly they are used for.

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
