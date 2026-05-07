# syntax=docker/dockerfile:1.7

FROM golang:1.26-alpine AS build
WORKDIR /src
COPY go.mod ./
RUN go mod download || true
COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -trimpath -ldflags="-s -w" -o /out/demo-nf ./

FROM gcr.io/distroless/static:nonroot
WORKDIR /
COPY --from=build /out/demo-nf /usr/local/bin/demo-nf
USER nonroot:nonroot
EXPOSE 9100
ENTRYPOINT ["/usr/local/bin/demo-nf"]
