package server

import (
	"context"
	"log"
	"net/http"
	"net/http/httputil"
	"net/url"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/rs/zerolog"
)

type MiddlewareFunc func(http.HandlerFunc) http.HandlerFunc

type Server struct {
	*http.Server
	config *config
	logger zerolog.Logger
}

func New(address string, options ...configOption) *Server {
	// setup config
	config := &config{
		out:         os.Stdout,
		middlewares: make([]MiddlewareFunc, 0),
	}
	for _, option := range options {
		option(config)
	}

	remote, _ := url.Parse("http://localhost:18080")
	proxy := httputil.NewSingleHostReverseProxy(remote)
	handler := func(writer http.ResponseWriter, req *http.Request) {
		req.Host = remote.Host
		proxy.ServeHTTP(writer, req)
	}
	for _, middleware := range config.middlewares {
		handler = middleware(handler)
	}

	// setup server
	return &Server{
		Server: &http.Server{Addr: address, Handler: http.HandlerFunc(handler)},
		config: config,
		logger: zerolog.New(config.out).With().Timestamp().Logger(),
	}
}

func (s *Server) Shutdown() error {
	signalChannel := make(chan os.Signal, 1)
	signal.Notify(signalChannel, syscall.SIGINT, syscall.SIGTERM, syscall.SIGHUP)
	log.Printf("SIGNAL %d received, then shutting down...\n", <-signalChannel)

	ctx, cancel := context.WithTimeout(context.Background(), 60*time.Second)
	defer cancel()
	return s.Server.Shutdown(ctx)
}

/*
func handlerFunc(writer http.ResponseWriter, req *http.Request) {
	body, err := json.MarshalIndent(map[string]string{
		"message": "hello!!",
	}, "", "  ")
	if err != nil {
		writer.WriteHeader(400)
		return
	}
	writer.Header().Set("Content-Type", "application/json")
	writer.WriteHeader(200)
	writer.Write(body)
}
*/
