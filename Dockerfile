FROM golang:1.20 AS builder

WORKDIR /app

COPY go.mod go.sum ./
RUN go mod download

COPY . .

WORKDIR /app/cmd/ordersystem
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -o /app/bin/ordersystem main.go wire_gen.go

FROM debian:bookworm-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    bash \
    netcat-openbsd \
    default-mysql-client \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app/cmd/ordersystem

COPY --from=builder /app/bin/ordersystem /app/ordersystem
COPY cmd/ordersystem/.env /app/cmd/ordersystem/.env
COPY migrations /app/migrations
COPY docker/entrypoint.sh /app/entrypoint.sh

RUN chmod +x /app/entrypoint.sh

EXPOSE 8000 50051 8080

ENTRYPOINT ["/app/entrypoint.sh"]