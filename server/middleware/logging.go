package middleware

import (
	"bytes"
	"io"
	"os"
	"time"

	"github.com/masashi-toda/go-gateway/server"
	"github.com/masashi-toda/go-gateway/server/api"
	"github.com/masashi-toda/go-gateway/server/logger"
	"github.com/masashi-toda/go-gateway/server/system"
)

type IsLoggingReqBodyFunc func(*api.Request) bool

func AccessLog(log *logger.Logger, skipPath []string, filter IsLoggingReqBodyFunc) server.MiddlewareFunc {
	var (
		hostName, _ = os.Hostname()
		isLogging   = func(path string) bool {
			for _, p := range skipPath {
				if p == path {
					return false
				}
			}
			return true
		}
	)
	return func(next server.HandlerFunc) server.HandlerFunc {
		return func(rw *api.ResponseWriter, req *api.Request) {
			if isLogging(req.URL.Path) {
				var (
					body []byte
					err  error
				)
				if filter(req) && req.ContentLength > 0 && req.Body != nil {
					if body, err = io.ReadAll(req.Body); err == nil {
						defer req.Body.Close()
						req.Body = io.NopCloser(bytes.NewBuffer(body))
					}
				}
				defer func(begin time.Time) {
					evt := log.Info().
						Int("status", rw.StatusCode()).
						Str("method", req.Method).
						Str("path", req.URL.Path).
						Str("query", req.URL.RawQuery).
						Str("protocol", req.Proto).
						Str("client_ip", req.ClientIP()).
						Str("useragent", req.UserAgent()).
						Str("referer", req.Referer()).
						Dur("latency", system.CurrentTime().Sub(begin)).
						Str("server", hostName)
					if len(body) > 0 {
						evt = evt.RawJSON("body", body)
					}
					evt.Send()
				}(system.CurrentTime())
			}
			next(rw, req)
		}
	}
}
