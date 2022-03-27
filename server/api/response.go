package api

import (
	"encoding/json"
	"net/http"
	"strings"

	"github.com/masashi-toda/go-gateway/server/logger"
)

func NewResponseWriter(rw http.ResponseWriter) *ResponseWriter {
	return &ResponseWriter{ResponseWriter: rw}
}

type ResponseWriter struct {
	http.ResponseWriter
	statusCode int
}

func (rw *ResponseWriter) StatusCode() int {
	return rw.statusCode
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

func (rw *ResponseWriter) WriteHeader(statusCode int) {
	rw.statusCode = statusCode
	rw.ResponseWriter.WriteHeader(statusCode)
}

func (rw *ResponseWriter) write(status int, obj interface{}) {
	body, err := toByteBody(obj)
	if err != nil {
		logger.Default().Error().Msgf("Failed to parse response body [%s]", err.Error())
		rw.WriteHeader(http.StatusInternalServerError)
		return
	}
	rw.WriteHeader(status)
	rw.Header().Set("Content-Type", "application/json")
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
