package middleware

import (
	"io"
	"net"
	"net/http"
	"os"
	"strings"
	"time"

	"github.com/rs/zerolog"

	"github.com/masashi-toda/go-gateway/server"
)

var NowFunc = time.Now

func AccessLog(out io.Writer) server.MiddlewareFunc {
	var (
		hostName, _ = os.Hostname()
		logger      = zerolog.New(out)
		isLogging   = func(path string) bool {
			for _, p := range []string{"/setting"} {
				if p == path {
					return false
				}
			}
			return true
		}
	)
	return func(next http.HandlerFunc) http.HandlerFunc {
		return func(writer http.ResponseWriter, req *http.Request) {
			if isLogging(req.URL.Path) {
				loggingWriter := &loggingResponseWriter{ResponseWriter: writer}
				defer func(begin time.Time) {
					logger.Log().
						Time("time", begin).
						Str("method", req.Method).
						Str("path", req.URL.Path).
						Str("query", req.URL.RawQuery).
						Str("protocol", req.Proto).
						Str("client_ip", clientIP(req)).
						Str("useragent", req.UserAgent()).
						Str("referer", req.Referer()).
						Int("status", loggingWriter.statusCode).
						Dur("latency", NowFunc().Sub(begin)).
						Str("server", hostName).
						Send()
				}(NowFunc())
				next(loggingWriter, req)
			} else {
				next(writer, req)
			}
		}
	}
}

type loggingRequestBody struct {
	http.ResponseWriter
	statusCode int
}

type loggingResponseWriter struct {
	http.ResponseWriter
	statusCode int
}

func (w *loggingResponseWriter) WriteHeader(statusCode int) {
	w.statusCode = statusCode
	w.ResponseWriter.WriteHeader(statusCode)
}

/*******************************************/
/* helper method
/*******************************************/

func clientIP(req *http.Request) string {
	if ip := req.Header.Get(headerXForwardedFor); ip != "" {
		i := strings.IndexAny(ip, ",")
		if i > 0 {
			return strings.TrimSpace(ip[:i])
		}
		return ip
	}
	if ip := req.Header.Get(headerXRealIP); ip != "" {
		return ip
	}
	ra, _, _ := net.SplitHostPort(req.RemoteAddr)
	return ra
}

const (
	headerXRealIP       = "X-Real-Ip"
	headerXForwardedFor = "X-Forwarded-For"
)
