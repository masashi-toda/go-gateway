package server_test

import (
	"bytes"
	"context"
	"fmt"
	"io"
	"net"
	"net/http"
	"net/http/httptest"
	"testing"
	"time"

	resty "github.com/go-resty/resty/v2"
	"github.com/stretchr/testify/assert"

	. "github.com/masashi-toda/go-gateway/server"
	"github.com/masashi-toda/go-gateway/server/api"
	"github.com/masashi-toda/go-gateway/server/logger"
	"github.com/masashi-toda/go-gateway/server/middleware"
)

func TestNew(t *testing.T) {
	var (
		proxyServerAddress string
		apiServerAddress   string
		path               = "/search"
		header             = map[string]string{
			"Content-Type": "application/json",
		}
		rawQuery = "reqid=xxxx"
		body     = `{
			"message": "hello"
		}`
		respStatus = http.StatusOK
		respBody   = `{
			"status": "ok"
		}`
	)
	// run inernal mock api server
	{
		listener, _ := net.Listen("tcp", "localhost:0")
		apiServerAddress = "http://" + listener.Addr().String()
		ts := httptest.Server{
			Listener: listener,
			Config: &http.Server{Handler: http.HandlerFunc(func(rw http.ResponseWriter, req *http.Request) {
				reqBody, err := io.ReadAll(req.Body)
				// assert proxy request
				if assert.NoError(t, err) {
					assert.Equal(t, path, req.URL.Path)
					assert.Equal(t, rawQuery, req.URL.RawQuery)
					assert.JSONEq(t, body, string(reqBody))
				}
				// write ok response
				rw.Header().Set("Content-Type", "application/json")
				rw.WriteHeader(respStatus)
				rw.Write([]byte(respBody))
			})},
		}
		ts.Start()
		defer ts.Close()
	}

	// run internal proxy server
	{
		listener, _ := net.Listen("tcp", "localhost:0")
		proxyServerAddress = "http://" + listener.Addr().String()
		listener.Close()
		srv := New(listener.Addr().String(),
			WithTargetHandler(func(req *api.Request) string {
				// return api server address
				return apiServerAddress
			}),
		)
		defer srv.Shutdown(context.Background())

		go func() {
			if err := srv.ListenAndServe(); err != http.ErrServerClosed {
				panic(err)
			}
		}()
	}

	// call rest api
	resp, err := resty.New().SetBaseURL(proxyServerAddress).
		R().
		SetHeaders(header).
		SetQueryString(rawQuery).
		SetBody(body).
		Post(path)

		// assert response
	if assert.NoError(t, err) {
		assert.Equal(t, "application/json", resp.Header().Get("Content-Type"))
		assert.Equal(t, respStatus, resp.StatusCode())
		assert.JSONEq(t, respBody, string(resp.Body()))
	}
}

func TestDefaultErrorHandler(t *testing.T) {
	var (
		proxyServerAddress string
	)

	// run internal proxy server
	{
		listener, _ := net.Listen("tcp", "localhost:0")
		proxyServerAddress = "http://" + listener.Addr().String()
		listener.Close()
		srv := New(listener.Addr().String(),
			WithTargetHandler(func(req *api.Request) string {
				// return invalid address
				return "http://go-gateway.xxxxxx..invalid.com"
			}),
			WithMaxIdleConns(1),
			WithIdleConnTimeout(1*time.Second),
			WithTcpConnTimeout(1*time.Second),
			WithLogger(logger.New(bytes.NewBuffer(nil))),
		)
		defer srv.Shutdown(context.Background())

		go func() {
			if err := srv.ListenAndServe(); err != http.ErrServerClosed {
				panic(err)
			}
		}()
	}

	// call rest api
	resp, err := resty.New().SetBaseURL(proxyServerAddress).
		R().
		Post("/search")

		// assert response
	if assert.NoError(t, err) {
		assert.Equal(t, "application/json", resp.Header().Get("Content-Type"))
		assert.Equal(t, http.StatusBadGateway, resp.StatusCode())
		assert.JSONEq(t, `{"message": "dial tcp: lookup go-gateway.xxxxxx..invalid.com: no such host"}`, string(resp.Body()))
	}
}

func TestCustomErrorHandler(t *testing.T) {
	var (
		proxyServerAddress string
	)

	// run internal proxy server
	{
		listener, _ := net.Listen("tcp", "localhost:0")
		proxyServerAddress = "http://" + listener.Addr().String()
		listener.Close()
		srv := New(listener.Addr().String(),
			WithTargetHandler(func(req *api.Request) string {
				// return invalid address
				return "http://go-gateway.xxxxxx..invalid.com"
			}),
			WithErrorHandler(func(rw *api.ResponseWriter, _ *api.Request, err error) {
				rw.BadGateway(fmt.Errorf("custom error [%s]", err.Error()))
			}),
		)
		defer srv.Shutdown(context.Background())

		go func() {
			if err := srv.ListenAndServe(); err != http.ErrServerClosed {
				panic(err)
			}
		}()
	}

	// call rest api
	resp, err := resty.New().SetBaseURL(proxyServerAddress).
		R().
		Post("/search")

		// assert response
	if assert.NoError(t, err) {
		assert.Equal(t, "application/json", resp.Header().Get("Content-Type"))
		assert.Equal(t, http.StatusBadGateway, resp.StatusCode())
		assert.JSONEq(t, `{"message": "custom error [dial tcp: lookup go-gateway.xxxxxx..invalid.com: no such host]"}`, string(resp.Body()))
	}
}

func TestTargetURLParseError(t *testing.T) {
	var (
		proxyServerAddress string
	)

	// run internal proxy server
	{
		listener, _ := net.Listen("tcp", "localhost:0")
		proxyServerAddress = "http://" + listener.Addr().String()
		listener.Close()
		srv := New(listener.Addr().String(),
			WithTargetHandler(func(req *api.Request) string {
				// return empty url for recovery middleware
				return ""
			}),
		)
		defer srv.Shutdown(context.Background())

		go func() {
			if err := srv.ListenAndServe(); err != http.ErrServerClosed {
				panic(err)
			}
		}()
	}

	// call rest api
	resp, err := resty.New().SetBaseURL(proxyServerAddress).
		R().
		Post("/search")

		// assert response
	if assert.NoError(t, err) {
		assert.Equal(t, "application/json", resp.Header().Get("Content-Type"))
		assert.Equal(t, http.StatusInternalServerError, resp.StatusCode())
		assert.JSONEq(t, `{"message": "Failed to parse target url"}`, string(resp.Body()))
	}
}

func TestPanicRecoveryWithMiddleware(t *testing.T) {
	var (
		proxyServerAddress string
	)

	// run internal proxy server
	{
		listener, _ := net.Listen("tcp", "localhost:0")
		proxyServerAddress = "http://" + listener.Addr().String()
		listener.Close()
		srv := New(listener.Addr().String(),
			WithMiddleware(
				middleware.Recovery(logger.New(bytes.NewBuffer(nil))),
			),
			WithTargetHandler(func(req *api.Request) string {
				// Invoke a panic function for recovery middleware
				panic("unexpected error !!!")
			}),
		)
		defer srv.Shutdown(context.Background())

		go func() {
			if err := srv.ListenAndServe(); err != http.ErrServerClosed {
				panic(err)
			}
		}()
	}

	// call rest api
	resp, err := resty.New().SetBaseURL(proxyServerAddress).
		R().
		Post("/search")

		// assert response
	if assert.NoError(t, err) {
		assert.Equal(t, "application/json", resp.Header().Get("Content-Type"))
		assert.Equal(t, http.StatusInternalServerError, resp.StatusCode())
		assert.JSONEq(t, `{"message": "unexpected error !!!"}`, string(resp.Body()))
	}
}

func newProxyAddress() string {
	listener, _ := net.Listen("tcp", "localhost:0")
	defer listener.Close()
	return "http://" + listener.Addr().String()
}
