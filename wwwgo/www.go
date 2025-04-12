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
var templates *template.Template

func init() {
	templates = template.Must(template.ParseFS(templatesFS, "templates/*.tmpl"))
}

func main() {
	fmt.Println(templates.DefinedTemplates())
	if err := run(); err != nil {
		fmt.Fprintf(os.Stderr, "%s\n", err)
		os.Exit(1)
	}
}

func run() error {
	// TODO: 404 page.
	// TODO: proper home page, transfer styles and assets
	http.HandleFunc("/", home)

	if err := http.ListenAndServe(":8080", nil); err != nil {
		return err
	}

	return nil
}

func home(res http.ResponseWriter, req *http.Request) {
	res.Header().Set("Content-Type", "text/plain; charset=utf-8")
	res.WriteHeader(http.StatusOK)
	templates.ExecuteTemplate(res, "home.tmpl", nil)
}
