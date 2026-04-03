package webserver

import (
	"net/http"

	"github.com/go-chi/chi/v5"
	"github.com/go-chi/chi/v5/middleware"
)

type Handler struct {
	Method  string
	Path    string
	Handler http.HandlerFunc
}

type WebServer struct {
	Router        chi.Router
	Handlers      []Handler
	WebServerPort string
}

func NewWebServer(serverPort string) *WebServer {
	return &WebServer{
		Router:        chi.NewRouter(),
		Handlers:      []Handler{},
		WebServerPort: serverPort,
	}
}

func (s *WebServer) AddHandler(method string, path string, handler http.HandlerFunc) {
	s.Handlers = append(s.Handlers, Handler{
		Method:  method,
		Path:    path,
		Handler: handler,
	})
}

func (s *WebServer) Start() {
	s.Router.Use(middleware.Logger)

	for _, h := range s.Handlers {
		s.Router.MethodFunc(h.Method, h.Path, h.Handler)
	}

	http.ListenAndServe(s.WebServerPort, s.Router)
}
