#!/bin/bash
set -eu
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
CHART_DIR=${CHART_DIR:-$SCRIPT_DIR/../../couchbase-operator}

docker run --rm --volume "${CHART_DIR}:/helm-docs" -u "$(id -u)" jnorwood/helm-docs:v1.5.0 --dry-run "$@"
