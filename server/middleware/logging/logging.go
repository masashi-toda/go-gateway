package logging

import (
	"net/http"
	"os"
	"time"

	"github.com/rs/zerolog"

	"github.com/masashi-toda/go-gateway/server"
)

var NowFunc = time.Now

func New(options ...configOption) server.MiddlewareFunc {
	config := &config{
		out:      os.Stdout,
		skipPath: make([]string, 0),
	}
	for _, option := range options {
		option(config)
	}

	return func(next http.HandlerFunc) http.HandlerFunc {
		return newHandler(next, config)
	}
}

func newHandler(next http.HandlerFunc, config *config) http.HandlerFunc {
	var (
		hostName, _ = os.Hostname()
		logger      = zerolog.New(config.out)
	)
	return func(writer http.ResponseWriter, req *http.Request) {
		if config.isLoggingPath(req.URL.Path) {
			loggingWriter := &loggingResponseWriter{ResponseWriter: writer}
			defer func(begin time.Time) {
				logger.Log().
					Time("time", begin).
					Str("method", req.Method).
					Str("path", req.URL.Path).
					Str("query", req.URL.RawQuery).
					Str("protocol", req.Proto).
					Str("client_ip", req.RemoteAddr).
					Str("useragent", req.UserAgent()).
					Str("referer", req.Referer()).
					Int("status", loggingWriter.statusCode).
					Dur("latency", NowFunc().Sub(begin)).
					Str("server", hostName).
					Msg("")
			}(NowFunc())
			next(loggingWriter, req)
		} else {
			next(writer, req)
		}
	}
}

type loggingResponseWriter struct {
	http.ResponseWriter
	statusCode int
}

func (w *loggingResponseWriter) WriteHeader(statusCode int) {
	w.statusCode = statusCode
	w.ResponseWriter.WriteHeader(statusCode)
}
