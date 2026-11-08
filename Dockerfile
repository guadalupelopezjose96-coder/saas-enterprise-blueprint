# =============================================================================
# CONTENEDOR INMUTABLE DISTROLESS (SLSA NIVEL 3 / CIS BENCHMARK NIVEL 2)
# Cumplimiento: ISO/IEC 27001:2022 (A.8.18, A.8.19, A.8.27) | SOC 2 (CC6.8)
# =============================================================================
FROM golang:1.22-alpine AS builder

WORKDIR /src
COPY go.mod go.sum ./
COPY vendor/ ./vendor/
COPY cmd/api/main.go ./cmd/api/main.go

# Compilación estática determinista usando los paquetes verificados en vendor/
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build \
    -mod=vendor \
    -ldflags="-w -s -extldflags '-static'" \
    -tags netgo,osusergo \
    -o /out/saas-api-service ./cmd/api/main.go

# Imagen final Distroless: sin shell (/bin/sh), sin gestor de paquetes, usuario nonroot (UID 65532)
FROM gcr.io/distroless/static-debian12:nonroot

COPY --from=builder /out/saas-api-service /saas-api-service

USER 65532:65532
EXPOSE 8443

ENTRYPOINT ["/saas-api-service"]
