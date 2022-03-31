package logger_test

import (
	"bytes"
	"fmt"
	"os"
	"testing"

	"github.com/rs/zerolog"
	"github.com/stretchr/testify/assert"

	. "github.com/masashi-toda/go-gateway/server/logger"
	"github.com/masashi-toda/go-gateway/server/system"
)

func TestLogger(t *testing.T) {
	type input struct {
		level  string
		logEvt func(*Logger) *zerolog.Event
	}
	host, _ := os.Hostname()

	for _, input := range []input{
		{
			level:  "debug",
			logEvt: func(l *Logger) *zerolog.Event { return l.Debug() },
		},
		{
			level:  "info",
			logEvt: func(l *Logger) *zerolog.Event { return l.Info() },
		},
		{
			level:  "warn",
			logEvt: func(l *Logger) *zerolog.Event { return l.Warn() },
		},
		{
			level:  "error",
			logEvt: func(l *Logger) *zerolog.Event { return l.Error() },
		},
	} {
		var (
			level  = input.level
			logEvt = input.logEvt
		)
		system.RunTest(t, fmt.Sprintf("%s message", level), func(t *testing.T) {
			var (
				buf      = bytes.NewBuffer(nil)
				expected = fmt.Sprintf(`{
					"level": "%s",
					"time": "2022-12-24T00:00:00+09:00",
					"server": "%s",
					"message": "%s message"
				}`, level, host, level)
			)
			logEvt(New(buf)).Msgf("%s message", level)

			// assert log message
			assert.JSONEq(t, expected, buf.String())
		})
	}

	// panic error test (with default logger)
	system.RunTest(t, fmt.Sprintf("panic message"), func(t *testing.T) {
		var (
			buf      = bytes.NewBuffer(nil)
			expected = fmt.Sprintf(`{
				"level": "panic",
				"time": "2022-12-24T00:00:00+09:00",
				"server": "%s",
				"message": "panic message"
			}`, host)
		)
		SetupDefaultLogger(buf)

		assert.Panics(t, func() {
			Default().Panic().Msg("panic message")
		})

		// assert log message
		assert.JSONEq(t, expected, buf.String())
	})
}
