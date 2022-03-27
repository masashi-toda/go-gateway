package server

import (
	"context"
	"net"
	"net/http"
	"net/http/httputil"
	"net/url"
	"os"
	"os/signal"
	"sync"
	"syscall"
	"time"

	"github.com/masashi-toda/go-gateway/server/api"
	"github.com/masashi-toda/go-gateway/server/logger"
)

type TargetHandlerFunc func(*api.Request) string
type HandlerFunc func(*api.ResponseWriter, *api.Request)
type MiddlewareFunc func(HandlerFunc) HandlerFunc
type ErrorHandlerFunc func(*api.ResponseWriter, *api.Request, error)

type Server struct {
	*http.Server
	targetHandler   TargetHandlerFunc
	middlewares     []MiddlewareFunc
	errorHandler    ErrorHandlerFunc
	maxIdleConns    int
	idleConnTimeout time.Duration
	tcpConnTimeout  time.Duration
	proxyCache      sync.Map
	log             *logger.Logger
}

func New(address string, options ...serverOption) *Server {
	// create server
	srv := &Server{
		middlewares:     make([]MiddlewareFunc, 0),
		errorHandler:    nil,
		maxIdleConns:    100,
		idleConnTimeout: 90 * time.Second,
		tcpConnTimeout:  30 * time.Second,
		proxyCache:      sync.Map{},
		log:             logger.New(os.Stdout),
	}

	// bind options
	for _, option := range options {
		option(srv)
	}

	// setup handler
	handler := func(rw *api.ResponseWriter, req *api.Request) {
		target, err := url.Parse(srv.targetHandler(req))
		if err != nil {
			srv.log.Panic().Msg("unknown target error")
		}
		req.Host = target.Host
		srv.newSingleHostReverseProxy(target).ServeHTTP(rw, req.Request)
	}
	for _, middleware := range srv.middlewares {
		handler = middleware(handler)
	}

	// setup default error handler
	if srv.errorHandler == nil {
		srv.errorHandler = func(rw *api.ResponseWriter, _ *api.Request, err error) {
			srv.log.Error().Msgf("http proxy error [%s]", err.Error())
			rw.BadGateway(err)
		}
	}

	// setup internal server
	srv.Server = &http.Server{
		Addr: address,
		Handler: http.HandlerFunc(func(rw http.ResponseWriter, req *http.Request) {
			handler(api.NewResponseWriter(rw), api.NewRequest(req))
		}),
	}
	return srv
}

func (srv *Server) AwaitShutdown(timeout time.Duration) error {
	signalChannel := make(chan os.Signal, 1)
	signal.Notify(signalChannel, syscall.SIGINT, syscall.SIGTERM, syscall.SIGHUP)
	srv.log.Info().Msgf("SIGNAL %d received, then shutting down...", <-signalChannel)

	ctx, cancel := context.WithTimeout(context.Background(), timeout)
	defer cancel()
	return srv.Server.Shutdown(ctx)
}

func (srv *Server) newSingleHostReverseProxy(target *url.URL) *httputil.ReverseProxy {
	if value, ok := srv.proxyCache.Load(target.Host); ok {
		return value.(*httputil.ReverseProxy)
	}
	proxy := httputil.NewSingleHostReverseProxy(target)
	proxy.Transport = &http.Transport{
		Proxy: http.ProxyFromEnvironment,
		DialContext: (&net.Dialer{
			Timeout:   srv.tcpConnTimeout,
			KeepAlive: srv.tcpConnTimeout,
		}).DialContext,
		ForceAttemptHTTP2:     true,
		MaxIdleConns:          srv.maxIdleConns,
		IdleConnTimeout:       srv.idleConnTimeout,
		TLSHandshakeTimeout:   10 * time.Second,
		ExpectContinueTimeout: 1 * time.Second,
	}
	proxy.ErrorHandler = func(rw http.ResponseWriter, req *http.Request, err error) {
		srv.errorHandler(api.NewResponseWriter(rw), api.NewRequest(req), err)
	}

	// store proxy cache
	srv.proxyCache.Store(target.Host, proxy)
	return proxy
}
