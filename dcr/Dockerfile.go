# syntax=docker/dockerfile:1
# Build:       docker build -f Dockerfile.go -t app .
# Multi-arch:  docker buildx build --platform linux/amd64,linux/arm64 -t app .
ARG GO_VERSION=1.27

# --platform=$BUILDPLATFORM -> compile natively, cross-compile via GOOS/GOARCH (fast multi-arch)
# CGO + cross-compile needs a C cross toolchain -> with CGO remove --platform=$BUILDPLATFORM
FROM --platform=$BUILDPLATFORM golang:${GO_VERSION}-alpine AS builder

WORKDIR /app

# Uncomment if CGO is required (also set CGO_ENABLED=1 and change runtime image below)
# RUN apk add --no-cache gcc musl-dev

# go.sum must exist (run `go mod tidy`); private modules: ENV GOPRIVATE=github.com/yourorg/*
RUN --mount=type=cache,target=/go/pkg/mod \
    --mount=type=bind,source=go.mod,target=go.mod \
    --mount=type=bind,source=go.sum,target=go.sum \
    go mod download

COPY . .

ARG TARGETOS
ARG TARGETARCH
ARG VERSION=dev
# ARG COMMIT=unknown

# Vendored deps (vendor/ committed): add -mod=vendor and drop the `go mod download` step
RUN --mount=type=cache,target=/go/pkg/mod \
    --mount=type=cache,target=/root/.cache/go-build \
    CGO_ENABLED=0 GOOS=$TARGETOS GOARCH=$TARGETARCH \
    go build -trimpath \
      -ldflags="-s -w -X main.version=${VERSION}" \
      -o /app/server .
    # go build ./cmd/server   <- if main package is not in root

# Runtime image options:
#   distroless/static-debian13  -> CGO_ENABLED=0 (has CA certs + tzdata, no shell)
#   distroless/base-debian13    -> CGO_ENABLED=1 (glibc)  NOTE: build on golang:${GO_VERSION}-trixie, not alpine
#   distroless/*:debug-nonroot  -> includes busybox shell for troubleshooting
#   scratch                     -> smallest, but copy CA certs/tzdata yourself
#   alpine:3.24                 -> if you need a shell / curl for HEALTHCHECK
FROM gcr.io/distroless/static-debian13:nonroot

WORKDIR /

COPY --from=builder /app/server /server
# COPY --from=builder /app/config.yaml /config.yaml
# For scratch only:
# COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/
# COPY --from=builder /usr/share/zoneinfo /usr/share/zoneinfo

# ENV TZ=UTC

EXPOSE 8080
USER nonroot:nonroot

# Distroless has no shell/curl -> implement a subcommand in the binary for healthchecks
# HEALTHCHECK --interval=30s --timeout=3s --retries=3 CMD ["/server", "healthcheck"]

ENTRYPOINT ["/server"]
# CMD ["--config", "/config.yaml"]
