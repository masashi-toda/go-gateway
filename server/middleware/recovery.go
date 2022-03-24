package middleware

import (
	"fmt"
	"io"
	"net/http"

	"github.com/rs/zerolog"

	"github.com/masashi-toda/go-gateway/server"
)

func Recovery(out io.Writer) server.MiddlewareFunc {
	var (
		logger = zerolog.New(out).With().Timestamp().Logger()
	)
	return func(next http.HandlerFunc) http.HandlerFunc {
		return func(writer http.ResponseWriter, req *http.Request) {
			defer func() {
				if r := recover(); r != nil {
					err, ok := r.(error)
					if !ok {
						err = fmt.Errorf("%v", r)
					}
					logger.Error().Stack().Err(err).Msg("panic recovered")
				}
			}()
			next(writer, req)
		}
	}
}
