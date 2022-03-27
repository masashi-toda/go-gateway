package api

import (
	"net"
	"net/http"
	"strings"
)

func NewRequest(req *http.Request) *Request {
	return &Request{Request: req}
}

type Request struct {
	*http.Request
}

func (req *Request) ClientIP() string {
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
