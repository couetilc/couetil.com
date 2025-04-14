# www

Go server powering the home page for my domain, [couetil.com](https://www.couetil.com).

TODO
- get other pages in here: (1) about (2) portfolio
- possible to include (1) time to serve request and (2) time since server boot in response?
- Dockerize this, so I can deploy an image on AWS Lambda. Resume will be a distinct build stage I pull the final files from.
- get resume page working


NOTE
- checkout `http/httptrace`, `http/httputil`, and `http/pprof` for robust web server. See what exactly they are used for.
- what middleware would I want to include? To avoid wrapping everything route with the middleware, is it possible to have a double layer of ServeMux? The first, which triggers a series of middleware, the second, which rendes a template or serves a static file?
    e.g.
        request --> [ mux / middleware for auth ]
                <if middleware ok>
                    --> [ mux / templates or static files ] 
                    --> response OK
                <else>
                    --> response UNAUTHORIZED
    code:
        func NewServer() {
            s := new(Server)
            routes = NewServeMux()
            routes.Handle("/api/v1/user", &UserHandler{})
            server.Handle("/api", &AuthHandler{token,&routes})
        }
        func (h *AuthHandler) ServeHTTP(w, r) {
            if r.Header().Get("Authorization") != h.token {
                writeNotAuthorized(w)
            } else {
                h.routes.ServeHTTP(w, r)
            }
        }
        // I may want to redefine server to have?
