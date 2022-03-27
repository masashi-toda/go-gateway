package middleware

import (
	"fmt"

	"github.com/masashi-toda/go-gateway/server"
	"github.com/masashi-toda/go-gateway/server/api"
	"github.com/masashi-toda/go-gateway/server/logger"
)

func Recovery(log *logger.Logger) server.MiddlewareFunc {
	return func(next server.HandlerFunc) server.HandlerFunc {
		return func(rw *api.ResponseWriter, req *api.Request) {
			defer func() {
				if r := recover(); r != nil {
					err, ok := r.(error)
					if !ok {
						err = fmt.Errorf("%v", r)
					}
					log.Error().Stack().Err(err).Msg("panic recovered")
					rw.InternalServerError(err)
				}
			}()
			next(rw, req)
		}
	}
}
