package logger

import (
	"io"
	"os"

	"github.com/rs/zerolog"

	"github.com/masashi-toda/go-gateway/server/system"
)

var (
	hostName, _   = os.Hostname()
	defaultLogger = New(os.Stdout)
)

func New(out io.Writer) *Logger {
	return &Logger{
		internal: zerolog.New(out),
	}
}

func Default() *Logger {
	return defaultLogger
}

func SetupDefaultLogger(out io.Writer) {
	defaultLogger = New(out)
}

type Logger struct {
	internal      zerolog.Logger
	withHostName  bool
	withTimestamp bool
}

func (l *Logger) Debug() *zerolog.Event {
	return withParams(l.internal.Debug())
}

func (l *Logger) Info() *zerolog.Event {
	return withParams(l.internal.Info())
}

func (l *Logger) Warn() *zerolog.Event {
	return withParams(l.internal.Warn())
}

func (l *Logger) Error() *zerolog.Event {
	return withParams(l.internal.Error())
}

func (l *Logger) Panic() *zerolog.Event {
	return withParams(l.internal.Panic())
}

func withParams(evt *zerolog.Event) *zerolog.Event {
	return evt.Time("time", system.CurrentTime()).
		Str("server", hostName)
}
