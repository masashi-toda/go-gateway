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
		internal: zerolog.New(out).With().Str("server", hostName).Logger(),
	}
}

func Default() *Logger {
	return defaultLogger
}

type Logger struct {
	internal zerolog.Logger
}

func (l *Logger) Debug() *zerolog.Event {
	return l.logEvent(zerolog.DebugLevel)
}

func (l *Logger) Info() *zerolog.Event {
	return l.logEvent(zerolog.InfoLevel)
}

func (l *Logger) Warn() *zerolog.Event {
	return l.logEvent(zerolog.WarnLevel)
}

func (l *Logger) Error() *zerolog.Event {
	return l.logEvent(zerolog.ErrorLevel)
}

func (l *Logger) Panic() *zerolog.Event {
	return l.logEvent(zerolog.PanicLevel)
}

func (l *Logger) Fatal() *zerolog.Event {
	return l.logEvent(zerolog.FatalLevel)
}

func (l *Logger) NoLevel() *zerolog.Event {
	return l.logEvent(zerolog.NoLevel)
}

func (l *Logger) Disabled() *zerolog.Event {
	return l.logEvent(zerolog.Disabled)
}

func (l *Logger) logEvent(level zerolog.Level) *zerolog.Event {
	return l.internal.WithLevel(level).Timestamp()
}

func init() {
	zerolog.TimestampFunc = system.CurrentTime
}
