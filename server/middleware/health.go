package middleware

import (
	"github.com/masashi-toda/go-gateway/server"
	"github.com/masashi-toda/go-gateway/server/api"
)

func Health(path string, body interface{}) server.MiddlewareFunc {
	return func(next server.HandlerFunc) server.HandlerFunc {
		return func(rw *api.ResponseWriter, req *api.Request) {
			if path == req.URL.Path {
				rw.OK(body)
			} else {
				next(rw, req)
			}
		}
	}
}
