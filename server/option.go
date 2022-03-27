package server

import (
	"time"

	"github.com/masashi-toda/go-gateway/server/logger"
)

type serverOption func(*Server)

func WithTargetHandler(targetHandler TargetHandlerFunc) serverOption {
	return func(srv *Server) {
		srv.targetHandler = targetHandler
	}
}

func WithMiddleware(middlewares ...MiddlewareFunc) serverOption {
	return func(srv *Server) {
		srv.middlewares = middlewares
	}
}

func WithErrorHandler(errorHandler ErrorHandlerFunc) serverOption {
	return func(srv *Server) {
		srv.errorHandler = errorHandler
	}
}

func WithMaxIdleConns(maxIdleConns int) serverOption {
	return func(srv *Server) {
		srv.maxIdleConns = maxIdleConns
	}
}

func WithIdleConnTimeout(idleConnTimeout time.Duration) serverOption {
	return func(srv *Server) {
		srv.idleConnTimeout = idleConnTimeout
	}
}

func WithTcpConnTimeout(tcpConnTimeout time.Duration) serverOption {
	return func(srv *Server) {
		srv.tcpConnTimeout = tcpConnTimeout
	}
}

func WithLogger(log *logger.Logger) serverOption {
	return func(srv *Server) {
		srv.log = log
	}
}
