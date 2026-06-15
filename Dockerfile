# syntax=docker/dockerfile:1

ARG DOTNET_VERSION=10.0
ARG REPO_URL=https://github.com/BG5ESN/fmo-server-authrozier-service.git
ARG REPO_REF=main

# ---------- build stage ----------
FROM mcr.microsoft.com/dotnet/sdk:${DOTNET_VERSION} AS build

ARG REPO_URL
ARG REPO_REF
ARG TARGETARCH
ARG RUNTIME_ID

WORKDIR /src

RUN apt-get update && \
    apt-get install -y --no-install-recommends git ca-certificates && \
    rm -rf /var/lib/apt/lists/*

RUN git clone --depth 1 --branch "${REPO_REF}" "${REPO_URL}" repo

WORKDIR /src/repo

RUN if [ -z "$RUNTIME_ID" ]; then \
      case "$TARGETARCH" in \
        amd64) echo "linux-x64" > /tmp/rid ;; \
        arm64) echo "linux-arm64" > /tmp/rid ;; \
        *) echo "Unsupported TARGETARCH=$TARGETARCH" && exit 1 ;; \
      esac; \
    else \
      echo "$RUNTIME_ID" > /tmp/rid; \
    fi

RUN dotnet restore ./src/Sas.csproj -r "$(cat /tmp/rid)"

RUN dotnet publish ./src/Sas.csproj \
    -c Release \
    -r "$(cat /tmp/rid)" \
    --self-contained true \
    -p:PublishSingleFile=true \
    -p:PublishTrimmed=false \
    -o /app/publish

# ---------- runtime stage ----------
FROM mcr.microsoft.com/dotnet/runtime-deps:${DOTNET_VERSION}

WORKDIR /app

RUN useradd -r -m -d /home/sas -s /usr/sbin/nologin sas

COPY --from=build /app/publish/ /app/

RUN cat > /usr/local/bin/docker-entrypoint.sh <<'EOF2'
#!/bin/sh
set -eu

set -- \
  ${SAS_SERVER_UID:+--server-uid "$SAS_SERVER_UID"} \
  ${SAS_SERVER_CALLSIGN:+--server-callsign "$SAS_SERVER_CALLSIGN"} \
  ${SAS_MQTT_HOST:+--mqtt-host "$SAS_MQTT_HOST"} \
  ${SAS_MQTT_PORT:+--mqtt-port "$SAS_MQTT_PORT"} \
  ${SAS_MQTT_USERNAME:+--mqtt-username "$SAS_MQTT_USERNAME"} \
  ${SAS_MQTT_PASSWORD:+--mqtt-password "$SAS_MQTT_PASSWORD"} \
  ${SAS_CERT_FINGERPRINT:+--cert-fingerprint "$SAS_CERT_FINGERPRINT"} \
  --http-addr "${SAS_HTTP_ADDR:-0.0.0.0}" \
  --http-port "${SAS_HTTP_PORT:-8080}" \
  "$@"

exec /app/Sas "$@"
EOF2

RUN chmod +x /app/Sas /usr/local/bin/docker-entrypoint.sh && \
    mkdir -p /home/sas/.sas && \
    chown -R sas:sas /app /home/sas/.sas /usr/local/bin/docker-entrypoint.sh

USER sas

ENV HOME=/home/sas
ENV DOTNET_SYSTEM_GLOBALIZATION_INVARIANT=1
ENV SAS_HTTP_ADDR=0.0.0.0
ENV SAS_HTTP_PORT=8080

VOLUME ["/home/sas/.sas"]

EXPOSE 8080

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
