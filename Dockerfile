FROM public.ecr.aws/bitnami/golang:1.18 as builder
WORKDIR /go/go-gateway/
COPY . .
RUN make mod-download
RUN make build

FROM public.ecr.aws/docker/library/alpine:latest
RUN apk --no-cache add ca-certificates
COPY --from=builder /go/go-gateway/bin/app /bin/app
ENTRYPOINT [ "/bin/app" ]
