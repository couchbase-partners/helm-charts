#!/bin/bash
set -eux
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

TOOL_DIR="${SCRIPT_DIR}/../tools/value-generation"
CRD_FILE=${CRD_FILE:-$SCRIPT_DIR/crds/couchbase.crds.yaml}

docker build -t operator-values-generator "${TOOL_DIR}"
docker run --rm -i operator-values-generator - < "${CRD_FILE}"