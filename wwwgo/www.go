package main

import (
	"fmt"
	"os"
	"net/http"
	"html/template"
	"embed"
)

type Server struct {
	http.Server
	http.ServeMux
	*template.Template
}

type TemplateHandler struct {
	*template.Template
	filename string
	status int
}

func (t *TemplateHandler) ServeHTTP(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "text/html; charset=utf-8")
	w.WriteHeader(t.status)
	t.ExecuteTemplate(w, t.filename, nil)
}

//go:embed templates
var templatesFS embed.FS

func main() {
	if err := run(); err != nil {
		fmt.Fprintf(os.Stderr, "%s\n", err)
		os.Exit(1)
	}
}

func run() error {
	if err := NewServer().ListenAndServe(); err != nil {
		return err
	}

	return nil
}

func NewServer() *Server {
	s := new(Server)
	s.Server.Addr = ":8080"
	s.Server.Handler = &s.ServeMux
	s.Template = template.Must(template.ParseFS(templatesFS, "templates/*.tmpl"))
	s.Handle("/{$}", &TemplateHandler{s.Template, "home.tmpl", http.StatusOK})
	s.Handle("/", &TemplateHandler{s.Template, "404.tmpl", http.StatusNotFound})
	return s
}
