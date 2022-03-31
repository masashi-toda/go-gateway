package middleware_test

import (
	"bytes"
	"errors"
	"fmt"
	"net/http"
	"os"
	"testing"

	"github.com/stretchr/testify/assert"

	"github.com/masashi-toda/go-gateway/server/api"
	"github.com/masashi-toda/go-gateway/server/logger"
	. "github.com/masashi-toda/go-gateway/server/middleware"
	"github.com/masashi-toda/go-gateway/server/system"
)

func TestAccessLog(t *testing.T) {
	var (
		host, _     = os.Hostname()
		respBuilder = api.TestResponseWriterBuilder{}
		reqBuilder  = api.TestRequestBuilder{
			URL:    "http://dummy.logging.com",
			Method: http.MethodGet,
			Path:   "/search",
			Body:   bytes.NewBufferString(`{"keyword": "hello"}`),
			Header: map[string]string{
				"Content-Type": "application/json",
			},
			RawQuery: "reqid=req-XXXXXXXXXXXXXXXXX&rewriter=rewrite_999",
		}
	)

	system.RunTest(t, "skip logging", func(t *testing.T) {
		var (
			buf      = bytes.NewBuffer(nil)
			skipPath = []string{reqBuilder.Path} // skip path
			filter   = func(req *api.Request) bool {
				return true
			}
			handler = func(rw *api.ResponseWriter, req *api.Request) {
				rw.OK(map[string]string{"message": "ok"})
			}
		)
		// call middleware function
		AccessLog(logger.New(buf), skipPath, filter)(handler)(respBuilder.Build(), reqBuilder.Build())

		// assert log message
		assert.Empty(t, buf.String())
	})

	system.RunTest(t, "ok response (without request body)", func(t *testing.T) {
		var (
			buf      = bytes.NewBuffer(nil)
			skipPath = []string{}
			filter   = func(req *api.Request) bool {
				return req.URL.Path != reqBuilder.Path
			}
			handler = func(rw *api.ResponseWriter, req *api.Request) {
				rw.OK(map[string]string{"message": "ok"})
			}
		)
		// call middleware function
		AccessLog(logger.New(buf), skipPath, filter)(handler)(respBuilder.Build(), reqBuilder.Build())

		expected := fmt.Sprintf(`{
			"level": "info",
			"time": "2022-12-24T00:00:00+09:00",
			"server": "%s",
			"status": 200,
			"method": "GET",
			"path": "/search",
			"query": "reqid=req-XXXXXXXXXXXXXXXXX&rewriter=rewrite_999",
			"protocol": "HTTP/1.1",
			"client_ip": "127.0.0.1",
			"useragent": "",
			"referer": "",
			"latency": 0,
			"host": "dummy.logging.com"
		}`, host)
		// assert log message
		assert.JSONEq(t, expected, buf.String())
	})

	system.RunTest(t, "ok response", func(t *testing.T) {
		var (
			buf      = bytes.NewBuffer(nil)
			skipPath = []string{}
			filter   = func(req *api.Request) bool {
				return true
			}
			handler = func(rw *api.ResponseWriter, req *api.Request) {
				rw.OK(map[string]string{"message": "ok"})
			}
		)
		// call middleware function
		AccessLog(logger.New(buf), skipPath, filter)(handler)(respBuilder.Build(), reqBuilder.Build())

		expected := fmt.Sprintf(`{
			"level": "info",
			"time": "2022-12-24T00:00:00+09:00",
			"server": "%s",
			"status": 200,
			"method": "GET",
			"path": "/search",
			"query": "reqid=req-XXXXXXXXXXXXXXXXX&rewriter=rewrite_999",
			"protocol": "HTTP/1.1",
			"client_ip": "127.0.0.1",
			"useragent": "",
			"referer": "",
			"latency": 0,
			"host": "dummy.logging.com",
			"body": {
				"keyword": "hello"
			}
		}`, host)
		// assert log message
		assert.JSONEq(t, expected, buf.String())
	})

	system.RunTest(t, "badrequest response", func(t *testing.T) {
		var (
			buf      = bytes.NewBuffer(nil)
			skipPath = []string{}
			filter   = func(req *api.Request) bool {
				return true
			}
			handler = func(rw *api.ResponseWriter, req *api.Request) {
				rw.BadRequest(errors.New("bad request"))
			}
		)
		// call middleware function
		AccessLog(logger.New(buf), skipPath, filter)(handler)(respBuilder.Build(), reqBuilder.Build())

		expected := fmt.Sprintf(`{
			"level": "error",
			"time": "2022-12-24T00:00:00+09:00",
			"server": "%s",
			"status": 400,
			"method": "GET",
			"path": "/search",
			"query": "reqid=req-XXXXXXXXXXXXXXXXX&rewriter=rewrite_999",
			"protocol": "HTTP/1.1",
			"client_ip": "127.0.0.1",
			"useragent": "",
			"referer": "",
			"latency": 0,
			"host": "dummy.logging.com",
			"body": {
				"keyword": "hello"
			}
		}`, host)
		// assert log message
		assert.JSONEq(t, expected, buf.String())
	})

	system.RunTest(t, "internal server error response", func(t *testing.T) {
		var (
			buf      = bytes.NewBuffer(nil)
			skipPath = []string{}
			filter   = func(req *api.Request) bool {
				return true
			}
			handler = func(rw *api.ResponseWriter, req *api.Request) {
				rw.InternalServerError(errors.New("unexpected error"))
			}
		)
		// call middleware function
		AccessLog(logger.New(buf), skipPath, filter)(handler)(respBuilder.Build(), reqBuilder.Build())

		expected := fmt.Sprintf(`{
			"level": "error",
			"time": "2022-12-24T00:00:00+09:00",
			"server": "%s",
			"status": 500,
			"method": "GET",
			"path": "/search",
			"query": "reqid=req-XXXXXXXXXXXXXXXXX&rewriter=rewrite_999",
			"protocol": "HTTP/1.1",
			"client_ip": "127.0.0.1",
			"useragent": "",
			"referer": "",
			"latency": 0,
			"host": "dummy.logging.com",
			"body": {
				"keyword": "hello"
			}
		}`, host)
		// assert log message
		assert.JSONEq(t, expected, buf.String())
	})
}
