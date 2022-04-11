package middleware

import (
	"bytes"
	"io"
	"net/http"
	"time"

	"github.com/masashi-toda/go-gateway/server"
	"github.com/masashi-toda/go-gateway/server/api"
	"github.com/masashi-toda/go-gateway/server/logger"
	"github.com/masashi-toda/go-gateway/server/system"
	"github.com/rs/zerolog"
)

type IsLoggingReqBodyFunc func(*api.Request) bool

func AccessLog(log *logger.Logger, skipPath []string, filter IsLoggingReqBodyFunc) server.MiddlewareFunc {
	var (
		isLogging = func(path string) bool {
			for _, p := range skipPath {
				if p == path {
					return false
				}
			}
			return true
		}
		logEvent = func(status int) *zerolog.Event {
			switch {
			case status >= http.StatusBadRequest && status < http.StatusInternalServerError:
				return log.Warn()
			case status >= http.StatusInternalServerError:
				return log.Error()
			default:
				return log.Info()
			}
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
						req.Body = io.NopCloser(bytes.NewBuffer(body))
					}
				}
				defer func(begin time.Time) {
					evt := logEvent(rw.StatusCode()).
						Int("status", rw.StatusCode()).
						Str("method", req.Method).
						Str("path", req.URL.Path).
						Str("query", req.URL.RawQuery).
						Interface("header", req.Header).
						Str("protocol", req.Proto).
						Str("client_ip", req.ClientIP()).
						Str("useragent", req.UserAgent()).
						Str("referer", req.Referer()).
						Dur("latency", system.CurrentTime().Sub(begin)).
						Str("target", req.Host).
						Int64("bytes_in", req.ContentLength).
						Int64("bytes_out", rw.Size())
					if len(body) > 0 {
						evt = evt.RawJSON("body", body)
					}
					// write access log
					evt.Send()
				}(system.CurrentTime())
			}
			// call next handler function
			next(rw, req)
		}
	}
}
