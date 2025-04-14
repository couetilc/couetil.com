package main

import (
	"fmt"
	"os"
	"net/http"
	"html/template"
	"embed"
	"time"
	"net/url"
	"strings"
)

type Server struct {
	http.Server
	http.ServeMux
}

func NewServer() *Server {
	s := new(Server)
	s.Server.Addr = ":8080"
	s.Server.Handler = &s.ServeMux
	nt := NewNestedTemplate(templatesFS)
	s.Handle("/{$}", nt.NewHandler("page_home.tmpl", http.StatusOK))
	s.Handle("/about/{$}", nt.NewHandler("page_about.tmpl", http.StatusOK))
	s.Handle("/portfolio/{$}", nt.NewHandler("page_portfolio.tmpl", http.StatusOK))
	s.Handle("/static/", http.FileServerFS(staticFS))
	s.Handle("/", nt.NewHandler("page_404.tmpl", http.StatusNotFound))
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
	c := &TemplateContext{time.Now().UTC(),r.URL}
	t.ExecuteTemplate(w, t.filename, c)
}

type TemplateContext struct {
	time.Time
	*url.URL
}

func (c *TemplateContext) HasPathPrefix(prefix string) bool {
	return strings.HasPrefix(c.Path, prefix)
}

//go:embed templates
var templatesFS embed.FS
//go:embed static
var staticFS embed.FS

func main() {
	if err := NewServer().ListenAndServe(); err != nil {
		fmt.Fprintf(os.Stderr, "%s\n", err)
		os.Exit(1)
	}
}
