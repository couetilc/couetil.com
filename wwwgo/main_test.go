package main

import (
	"testing"
	"net/http"
	"net/http/httptest"
	"strings"
	"io/ioutil"
)

type TestCase struct {
	route string
	matchStatus int
	matchHeader string
	matchBody string
}

var testcases []TestCase

func init() {
	testcases = []TestCase{
		{
			route: "/",
			matchStatus: http.StatusOK,
			matchHeader: "text/html",
			matchBody: "Connor Couetil",
		},
		{
			route: "/404",
			matchStatus: http.StatusNotFound,
			matchHeader: "text/html",
			matchBody: "404",
		},
		{
			route: "/static/",
			matchStatus: http.StatusOK,
			matchHeader: "text/html",
			matchBody: "index.js",
		},
		{
			route: "/portfolio",
			matchStatus: http.StatusOK,
			matchHeader: "text/html",
			matchBody: "Portfolio",
		},
		{
			route: "/about",
			matchStatus: http.StatusOK,
			matchHeader: "text/html",
			matchBody: "About",
		},
	}
}

func TestRoutes(t *testing.T) {
	s := NewServer()
	ts := httptest.NewServer(s)
	defer ts.Close()

	for _, testcase := range testcases {
		res, err := http.Get(ts.URL + testcase.route)
		if err != nil {
			t.Fatalf("GET %s failed: %v", testcase.route, err)
		}
		defer res.Body.Close()

		if res.StatusCode != testcase.matchStatus {
			t.Errorf("For route %s, expected status %d, got %d", testcase.route, testcase.matchStatus, res.StatusCode)
		}

		contentType := res.Header.Get("Content-Type")
		if !strings.Contains(contentType, testcase.matchHeader) {
			t.Errorf("For route %s, expected Content-Type to contain %q, got %q", testcase.route, testcase.matchHeader, contentType)
		}

		bodyBytes, err := ioutil.ReadAll(res.Body)
		if err != nil {
			t.Fatalf("Reading body for %s failed: %v", testcase.route, err)
		}

		body := string(bodyBytes)
		if !strings.Contains(body, testcase.matchBody) {
			t.Errorf("For route %s, expected body to contain %q, got %q", testcase.route, testcase.matchBody, body)
		}
	}
}
