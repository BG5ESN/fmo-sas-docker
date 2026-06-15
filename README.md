# fmo-sas Docker Image

This package contains:

- `Dockerfile`: builds `BG5ESN/fmo-server-authrozier-service` inside Docker and exposes configuration through environment variables.
- `.github/workflows/docker-ghcr.yml`: GitHub Actions workflow for multi-arch image build and push to GHCR.
- `docker-compose.yml`: example runtime configuration.

## Build locally

```bash
docker build -t fmo-sas:env .
```

## Run locally

```bash
docker run -d \
  --name fmo-sas \
  -p 8080:8080 \
  -v fmo-sas-data:/home/sas/.sas \
  -e SAS_SERVER_UID=12345 \
  -e SAS_SERVER_CALLSIGN=BG5ESN \
  -e SAS_MQTT_HOST=your-mqtt-broker.com \
  -e SAS_MQTT_PORT=1883 \
  -e SAS_MQTT_USERNAME=your_username \
  -e SAS_MQTT_PASSWORD=your_password \
  -e SAS_CERT_FINGERPRINT=gjJGc7xxxxxxxxxxxxxxxxxY \
  fmo-sas:env
```

## GHCR image path

By default, the workflow pushes to:

```text
ghcr.io/<github-owner>/<repository>:latest
```

To use a fixed package name, edit `.github/workflows/docker-ghcr.yml`:

```yaml
env:
  REGISTRY: ghcr.io
  IMAGE_NAME: ${{ github.repository_owner }}/fmo-sas
```
