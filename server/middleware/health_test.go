package middleware_test

import (
	"net/http"
	"testing"

	"github.com/stretchr/testify/assert"
	"golang.org/x/xerrors"

	"github.com/masashi-toda/go-gateway/server/api"
	. "github.com/masashi-toda/go-gateway/server/middleware"
	"github.com/masashi-toda/go-gateway/server/system"
)

func TestHealth(t *testing.T) {
	var (
		respBuilder = api.TestResponseWriterBuilder{}
		reqBuilder  = api.TestRequestBuilder{
			URL:    "http://dummy.logging.com",
			Method: http.MethodGet,
			Path:   "/health",
		}
	)

	system.RunTest(t, "success response", func(t *testing.T) {
		var (
			handler = func(rw *api.ResponseWriter, req *api.Request) {
				rw.BadRequest(xerrors.New("validation error")) // not called
			}
			resp = respBuilder.Build()
			body interface{}
		)
		// call middleware function
		Health("/health", body)(handler)(resp, reqBuilder.Build())

		// assert response
		assert.Equal(t, http.StatusOK, resp.StatusCode())
	})

	system.RunTest(t, "skip healthcheck", func(t *testing.T) {
		var (
			handler = func(rw *api.ResponseWriter, req *api.Request) {
				rw.BadRequest(xerrors.New("validation error")) // not called
			}
			resp = respBuilder.Build()
			body interface{}
		)
		// call middleware function
		Health("/search", body)(handler)(resp, reqBuilder.Build())

		// assert response
		assert.Equal(t, http.StatusBadRequest, resp.StatusCode())
	})
}
