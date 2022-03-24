package main

import (
	"net/http"
	"os"

	"github.com/rs/zerolog"

	"github.com/masashi-toda/go-gateway/server"
	"github.com/masashi-toda/go-gateway/server/middleware"
)

func main() {
	var (
		hostName, _ = os.Hostname()
		out         = os.Stdout
		logger      = zerolog.New(out).With().Timestamp().Str("server", hostName).Logger()
		middlewares = []server.MiddlewareFunc{
			middleware.AccessLog(out),
			middleware.Recovery(out),
		}
		srv = server.New(":8080",
			server.WithWriter(out),
			server.WithMiddleware(middlewares...),
		)
	)

	go func() {
		logger.Info().Msg("Startup server")
		if err := srv.ListenAndServe(); err != http.ErrServerClosed {
			logger.Error().Err(err).Msg("Failed to close server")
		}
	}()

	if err := srv.Shutdown(); err != nil {
		logger.Error().Err(err).Msg("Failed to gracefully shutdown")
	}
	logger.Info().Msg("Shutdown server")
}
