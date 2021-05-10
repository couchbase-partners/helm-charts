#!/bin/bash
set -eux
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

CRD_FILE=${CRD_FILE:-$SCRIPT_DIR/crds/couchbase.crds.yaml}
CHART_DIR=${CHART_DIR:-$SCRIPT_DIR}

CRD_FILE=${CRD_FILE} /bin/bash "${SCRIPT_DIR}/../tools/value-generation/generateValuesFile.sh"
CHART_DIR=${CHART_DIR} /bin/bash "${SCRIPT_DIR}/../tools/value-generation/generateDocumentation.sh"
