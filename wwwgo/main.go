package main

import (
	"os"
	"net/http"
	"html/template"
	"embed"
	"time"
	"net/url"
	"strings"
	"log/slog"
	"flag"
)

type Server struct {
	http.Server
}

func NewServer(addr *string) *Server {
	nt := NewNestedTemplate(templatesFS)

	mux := new(http.ServeMux)
	mux.Handle("/{$}", nt.NewHandler("page_home.tmpl", http.StatusOK))
	mux.Handle("/about/{$}", nt.NewHandler("page_about.tmpl", http.StatusOK))
	mux.Handle("/portfolio/{$}", nt.NewHandler("page_portfolio.tmpl", http.StatusOK))
	mux.Handle("/static/", http.FileServerFS(staticFS))
	mux.Handle("/", nt.NewHandler("page_404.tmpl", http.StatusNotFound))

	s := new(Server)
	s.Addr = *addr
	s.Handler = &RequestLogger{mux}

	return s
}

type NestedTemplate struct {
	*template.Template
	embed.FS
}

type NestedTemplateHandler struct {
	*template.Template
	filename string
	status int
}

func NewNestedTemplate(fs embed.FS) *NestedTemplate {
	t := new(NestedTemplate)
	t.Template = template.Must(template.ParseFS(fs, "templates/layout_*.tmpl", "templates/partial_*.tmpl"))
	t.FS = fs
	return t
}

func (nt *NestedTemplate) NewHandler(filename string, status int) *NestedTemplateHandler {
	h := new(NestedTemplateHandler)
	clone := template.Must(nt.Clone())
	h.Template = template.Must(clone.ParseFS(nt.FS, "templates/" + filename))
	h.filename = filename
	h.status = status
	return h
}

func (t *NestedTemplateHandler) ServeHTTP(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "text/html; charset=utf-8")
	w.WriteHeader(t.status)
	c := &TemplateContext{r.URL}
	t.ExecuteTemplate(w, t.filename, c)
}

type TemplateContext struct {
	*url.URL
}

func (c *TemplateContext) HasPathPrefix(prefix string) bool {
	return strings.HasPrefix(c.Path, prefix)
}

func (c *TemplateContext) NowTime() string {
	return time.Now().Format(time.UnixDate)
}

func (c *TemplateContext) UpTime() string {
	return time.Now().Sub(bootTime).String()
}

type RequestLogger struct {
	handler http.Handler
}

func (rl *RequestLogger) ServeHTTP(w http.ResponseWriter, r *http.Request) {
	rl.handler.ServeHTTP(w, r)

	slog.Info(
		"http_request",
		"url",
		r.URL,
		"method",
		r.Method,
	)
}

//go:embed templates
var templatesFS embed.FS
//go:embed static
var staticFS embed.FS
var bootTime time.Time

func init() {
	bootTime = time.Now()
	slog.Info("boot", "time", bootTime.UTC().Format(time.UnixDate))
}

func main() {
	addr := flag.String("addr", ":http", "TCP address for server to listen on. See net.Dial for address format.")
	flag.Parse()

	if err := NewServer(addr).ListenAndServe(); err != nil {
		slog.Error("exit", "error", err)
		os.Exit(1)
	}
}
