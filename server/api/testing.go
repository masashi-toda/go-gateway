package api

import (
	"bytes"
	"net/http/httptest"
	"strings"
)

type TestRequestBuilder struct {
	URL      string
	Method   string
	Path     string
	Body     *bytes.Buffer
	Header   map[string]string
	RawQuery string
	copyBody []byte
}

func (req TestRequestBuilder) Build() *Request {
	path := req.Path
	if !strings.HasPrefix(path, "/") {
		path += "/"
	}
	if req.Body != nil && len(req.copyBody) == 0 {
		req.copyBody = req.Body.Bytes()
		req.Body = bytes.NewBuffer(req.copyBody)
	} else {
		req.Body = bytes.NewBuffer(nil)
	}
	httpReq := httptest.NewRequest(
		strings.ToUpper(req.Method),
		req.URL+path,
		req.Body,
	)
	if len(req.Header) > 0 {
		for k, v := range req.Header {
			httpReq.Header.Add(k, v)
		}
	}
	if req.RawQuery != "" {
		httpReq.URL.RawQuery = req.RawQuery
	}
	httpReq.RemoteAddr = "127.0.0.1:8080"
	return NewRequest(httpReq)
}

type TestResponseWriterBuilder struct {
}

func (rw TestResponseWriterBuilder) Build() *ResponseWriter {
	return NewResponseWriter(httptest.NewRecorder())
}
