FROM golang:1.18.0 as builder
WORKDIR /go/go-gateway/
COPY . .
RUN make mod-download
RUN make build

FROM alpine:latest
RUN apk --no-cache add ca-certificates
WORKDIR /root/
COPY --from=builder /go/go-gateway/bin/app .
CMD ["./app"]
