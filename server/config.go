package server

import "io"

type configOption func(*config)

type config struct {
	out         io.Writer
	middlewares []MiddlewareFunc
}

func WithWriter(out io.Writer) configOption {
	return func(c *config) {
		c.out = out
	}
}

func WithMiddleware(middlewares ...MiddlewareFunc) configOption {
	return func(c *config) {
		c.middlewares = middlewares
	}
}
