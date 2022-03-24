package logging

import "io"

type configOption func(*config)

type config struct {
	out      io.Writer
	skipPath []string
}

func (c *config) isLoggingPath(path string) bool {
	for _, p := range c.skipPath {
		if p == path {
			return false
		}
	}
	return true
}

func WithWriter(out io.Writer) configOption {
	return func(c *config) {
		c.out = out
	}
}

func WithSkipPath(skipPath []string) configOption {
	return func(c *config) {
		c.skipPath = skipPath
	}
}
