package main

import (
	"fmt"
	"os"
	"net/http"
	"html/template"
	"embed"
)

//go:embed templates
var templatesFS embed.FS
var tmpls *template.Template

func init() {
	tmpls = template.Must(template.ParseFS(templatesFS, "templates/*.tmpl"))
}

func main() {
	if err := run(); err != nil {
		fmt.Fprintf(os.Stderr, "%s\n", err)
		os.Exit(1)
	}
}

func run() error {
	// TODO: proper home page, transfer styles and assets
	http.HandleFunc("/{$}", home)

	// 404 route
	http.Handle("/...", http.NotFoundHandler())

	if err := http.ListenAndServe(":8080", nil); err != nil {
		return err
	}

	return nil
}

func home(res http.ResponseWriter, req *http.Request) {
	res.Header().Set("Content-Type", "text/plain; charset=utf-8")
	res.WriteHeader(http.StatusOK)
	tmpls.ExecuteTemplate(res, "home.tmpl", nil)
}
