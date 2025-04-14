package main

import (
	"fmt"
	"os"
	"net/http"
	"html/template"
	"embed"
	"time"
)

type Server struct {
	http.Server
	http.ServeMux
}

func NewServer() *Server {
	s := new(Server)
	s.Server.Addr = ":8080"
	s.Server.Handler = &s.ServeMux
	tfs := template.Must(template.ParseFS(templatesFS, "templates/*.tmpl"))
	s.Handle("/{$}", &TemplateHandler{tfs, "home.tmpl", http.StatusOK})
	s.Handle("/static/", http.FileServerFS(staticFS))
	s.Handle("/", &TemplateHandler{tfs, "404.tmpl", http.StatusNotFound})
	return s
}

type TemplateHandler struct {
	*template.Template
	filename string
	status int
}

func (t *TemplateHandler) ServeHTTP(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "text/html; charset=utf-8")
	w.WriteHeader(t.status)
	t.ExecuteTemplate(w, t.filename, time.Now().UTC())
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
