package main

import (
	"net/http"
	"os"
	"strings"
	"time"

	"github.com/masashi-toda/go-gateway/server"
	"github.com/masashi-toda/go-gateway/server/api"
	"github.com/masashi-toda/go-gateway/server/logger"
	"github.com/masashi-toda/go-gateway/server/middleware"
	"github.com/masashi-toda/go-gateway/server/system"
)

var (
	name     = "go-gateway"
	version  string
	revision string
)

func main() {
	var (
		address       = ":8080"
		log           = logger.New(os.Stdout)
		targetHandler = func(req *api.Request) string {
			return "http://localhost:18080"
		}
		errorHandler = func(rw *api.ResponseWriter, _ *api.Request, err error) {
			rw.InternalServerError(err)
		}
		accessLogFilter = func(req *api.Request) bool {
			return strings.HasPrefix(req.URL.Path, "/search")
		}
		healthCheckResp = map[string]string{
			"name":       name,
			"version":    version,
			"revision":   revision,
			"started_at": system.CurrentTime().Format(time.RFC3339),
		}
		middlewares = []server.MiddlewareFunc{
			middleware.Recovery(log),
			middleware.AccessLog(log, []string{"/favicon.ico"}, accessLogFilter),
			middleware.Health("/health", healthCheckResp),
		}
		srv = server.New(address,
			server.WithTargetHandler(targetHandler),
			server.WithMiddleware(middlewares...),
			server.WithErrorHandler(errorHandler),
			server.WithMaxIdleConns(100),
			server.WithIdleConnTimeout(60*time.Second),
			server.WithTcpConnTimeout(30*time.Second),
			server.WithLogger(log),
		)
	)

	go func() {
		log.Info().Msg("Startup server...")
		if err := srv.ListenAndServe(); err != http.ErrServerClosed {
			log.Error().Err(err).Msg("Failed to close server")
		}
	}()

	if err := srv.AwaitShutdown(60 * time.Second); err != nil {
		log.Error().Err(err).Msg("Failed to gracefully shutdown")
	}
	log.Info().Msg("Shutdown server")
}
