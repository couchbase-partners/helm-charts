#!/bin/bash
set -eux
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
TOOL_DIR="${SCRIPT_DIR}/../tools/value-generation"

CRD_FILE=${CRD_FILE:-$SCRIPT_DIR/crds/couchbase.crds.yaml}
VALUES_FILE=${VALUES_FILE:-$SCRIPT_DIR/new-values.yaml}

cp -f "${CRD_FILE}" "${TOOL_DIR}/crd.yaml"
docker build -t operator-values-generator "${TOOL_DIR}"
rm -f "${TOOL_DIR}/crd.yaml"
docker run --rm operator-values-generator > "${VALUES_FILE}"
cat "${VALUES_FILE}"
