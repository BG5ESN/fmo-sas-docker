#!/bin/sh
set -eu

ARGS=""

append_arg() {
    name="$1"
    value="$2"

    if [ -n "$value" ]; then
        ARGS="$ARGS $name $value"
    fi
}

append_arg "--server-uid" "${SAS_SERVER_UID:-}"
append_arg "--server-callsign" "${SAS_SERVER_CALLSIGN:-}"
append_arg "--mqtt-host" "${SAS_MQTT_HOST:-}"
append_arg "--mqtt-port" "${SAS_MQTT_PORT:-}"
append_arg "--mqtt-username" "${SAS_MQTT_USERNAME:-}"
append_arg "--mqtt-password" "${SAS_MQTT_PASSWORD:-}"
append_arg "--cert-fingerprint" "${SAS_CERT_FINGERPRINT:-}"
append_arg "--http-addr" "${SAS_HTTP_ADDR:-0.0.0.0}"
append_arg "--http-port" "${SAS_HTTP_PORT:-8080}"

exec /app/Sas $ARGS "$@"