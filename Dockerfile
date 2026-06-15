# syntax=docker/dockerfile:1

ARG DOTNET_VERSION=10.0
ARG ALPINE_VERSION=3.22
ARG REPO_URL=https://github.com/BG5ESN/fmo-server-authrozier-service.git
ARG REPO_REF=main

# ---------- build stage ----------
FROM mcr.microsoft.com/dotnet/sdk:${DOTNET_VERSION}-alpine AS build

ARG REPO_URL
ARG REPO_REF
ARG TARGETARCH
ARG RUNTIME_ID

WORKDIR /src

RUN apk add --no-cache git ca-certificates

RUN git clone --depth 1 --branch "${REPO_REF}" "${REPO_URL}" repo

WORKDIR /src/repo

RUN if [ -z "$RUNTIME_ID" ]; then \
      case "$TARGETARCH" in \
        amd64) echo "linux-musl-x64" > /tmp/rid ;; \
        arm64) echo "linux-musl-arm64" > /tmp/rid ;; \
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
    -p:DebugType=None \
    -p:DebugSymbols=false \
    -o /app/publish

# ---------- runtime stage ----------
FROM alpine:3.22

WORKDIR /app

RUN apk add --no-cache \
      ca-certificates \
      libgcc \
      libstdc++ \
      zlib && \
    addgroup -S sas && \
    adduser -S -D -h /home/sas -s /sbin/nologin -G sas sas && \
    mkdir -p /home/sas/.sas && \
    chown -R sas:sas /home/sas/.sas

COPY --from=build --chown=sas:sas --chmod=755 /app/publish/Sas /app/Sas

COPY --chown=root:root --chmod=755 docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh

USER sas

ENV HOME=/home/sas
ENV DOTNET_SYSTEM_GLOBALIZATION_INVARIANT=1
ENV SAS_HTTP_ADDR=0.0.0.0
ENV SAS_HTTP_PORT=8080

VOLUME ["/home/sas/.sas"]

EXPOSE 8080

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]