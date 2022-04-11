package api

import (
	"bufio"
	"encoding/json"
	"net"
	"net/http"
	"strings"

	"github.com/masashi-toda/go-gateway/server/logger"
)

func NewResponseWriter(rw http.ResponseWriter) *ResponseWriter {
	return &ResponseWriter{writer: rw}
}

type ResponseWriter struct {
	writer     http.ResponseWriter
	statusCode int
	size       int64
	committed  bool
}

func (rw *ResponseWriter) StatusCode() int {
	return rw.statusCode
}

func (rw *ResponseWriter) Size() int64 {
	return rw.size
}

// OK is ...
func (rw *ResponseWriter) OK(body interface{}) {
	rw.write(http.StatusOK, body)
}

// Created is ...
func (rw *ResponseWriter) Created(body interface{}) {
	rw.write(http.StatusCreated, body)
}

// NoContent is ...
func (rw *ResponseWriter) NoContent() {
	rw.write(http.StatusNoContent, nil)
}

// BadRequest is ...
func (rw *ResponseWriter) BadRequest(err error) {
	rw.write(http.StatusBadRequest, err)
}

// Unauthorized is ...
func (rw *ResponseWriter) Unauthorized(err error) {
	rw.write(http.StatusUnauthorized, err)
}

// NotFound is ...
func (rw *ResponseWriter) NotFound(err error) {
	rw.write(http.StatusNotFound, err)
}

// ProxyAuthRequired is ...
func (rw *ResponseWriter) ProxyAuthRequired(err error) {
	rw.write(http.StatusProxyAuthRequired, err)
}

// Conflict is ...
func (rw *ResponseWriter) Conflict(err error) {
	rw.write(http.StatusConflict, err)
}

// InternalServerError is ...
func (rw *ResponseWriter) InternalServerError(err error) {
	rw.write(http.StatusInternalServerError, err)
}

// StatusBadGateway is ...
func (rw *ResponseWriter) BadGateway(err error) {
	rw.write(http.StatusBadGateway, err)
}

/***********************************************
# Private functions
************************************************/
func (rw *ResponseWriter) write(status int, obj interface{}) {
	body, err := toByteBody(obj)
	if err != nil {
		logger.Default().Error().Msgf("Failed to parse response body [%s]", err.Error())
		rw.WriteHeader(http.StatusInternalServerError)
		return
	}
	rw.Header().Set("Content-Type", "application/json")
	rw.WriteHeader(status)
	if body != nil {
		if _, err := rw.Write(body); err != nil {
			logger.Default().Error().Msgf("Failed to write response body [%s]", err.Error())
		}
	}
}

func toByteBody(obj interface{}) ([]byte, error) {
	if obj == nil {
		return nil, nil
	}
	switch body := obj.(type) {
	case []byte:
		return body, nil
	case error:
		return json.Marshal(&map[string]string{
			"message": body.Error(),
		})
	case string:
		if strings.HasPrefix(body, "{") && strings.HasSuffix(body, "}") {
			return []byte(body), nil
		}
		return json.Marshal(&map[string]string{
			"message": body,
		})
	default:
		return json.Marshal(obj)
	}
}

/***********************************************
# Override ResponseWriter functions
************************************************/
func (rw *ResponseWriter) Header() http.Header {
	return rw.writer.Header()
}

func (rw *ResponseWriter) WriteHeader(statusCode int) {
	if rw.committed {
		logger.Default().Warn().Msg("response already committed")
		return
	}
	rw.statusCode = statusCode
	rw.writer.WriteHeader(statusCode)
	rw.committed = true
}

func (rw *ResponseWriter) Write(raw []byte) (len int, err error) {
	if !rw.committed {
		rw.WriteHeader(http.StatusOK)
	}
	len, err = rw.writer.Write(raw)
	rw.size += int64(len)
	return
}

// Flush implements the http.Flusher interface to allow an HTTP handler to flush
// buffered data to the client.
// See [http.Flusher](https://golang.org/pkg/net/http/#Flusher)
func (rw *ResponseWriter) Flush() {
	rw.writer.(http.Flusher).Flush()
}

// Hijack implements the http.Hijacker interface to allow an HTTP handler to
// take over the connection.
// See [http.Hijacker](https://golang.org/pkg/net/http/#Hijacker)
func (rw *ResponseWriter) Hijack() (net.Conn, *bufio.ReadWriter, error) {
	return rw.writer.(http.Hijacker).Hijack()
}
