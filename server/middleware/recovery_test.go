package middleware_test

import (
	"bytes"
	"fmt"
	"net/http"
	"os"
	"testing"

	"github.com/stretchr/testify/assert"
	"golang.org/x/xerrors"

	"github.com/masashi-toda/go-gateway/server/api"
	"github.com/masashi-toda/go-gateway/server/logger"
	. "github.com/masashi-toda/go-gateway/server/middleware"
	"github.com/masashi-toda/go-gateway/server/system"
)

func TestRecovery(t *testing.T) {
	var (
		host, _     = os.Hostname()
		respBuilder = api.TestResponseWriterBuilder{}
		reqBuilder  = api.TestRequestBuilder{
			URL:    "http://dummy.logging.com",
			Method: http.MethodGet,
			Path:   "/search",
		}
	)

	system.RunTest(t, "handle panic error", func(t *testing.T) {
		var (
			buf     = bytes.NewBuffer(nil)
			handler = func(rw *api.ResponseWriter, req *api.Request) {
				panic(xerrors.New("connection error"))
			}
			resp = respBuilder.Build()
		)
		// call middleware function
		Recovery(logger.New(buf))(handler)(resp, reqBuilder.Build())

		expected := fmt.Sprintf(`{
			"level": "error",
			"time": "2022-12-24T00:00:00+09:00",
			"server": "%s",
			"error": "connection error",
			"message": "panic recovered"
		}`, host)
		// assert log message
		assert.JSONEq(t, expected, buf.String())
		// assert error response
		assert.Equal(t, http.StatusInternalServerError, resp.StatusCode())
	})

	system.RunTest(t, "handle panic error (not error type)", func(t *testing.T) {
		var (
			buf     = bytes.NewBuffer(nil)
			handler = func(rw *api.ResponseWriter, req *api.Request) {
				panic("string message error")
			}
			resp = respBuilder.Build()
		)
		// call middleware function
		Recovery(logger.New(buf))(handler)(resp, reqBuilder.Build())

		expected := fmt.Sprintf(`{
			"level": "error",
			"time": "2022-12-24T00:00:00+09:00",
			"server": "%s",
			"error": "string message error",
			"message": "panic recovered"
		}`, host)
		// assert log message
		assert.JSONEq(t, expected, buf.String())
		// assert error response
		assert.Equal(t, http.StatusInternalServerError, resp.StatusCode())
	})
}
