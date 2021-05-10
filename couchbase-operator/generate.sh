#!/bin/bash
set -eux
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

# Defaults to everything required locally but useful for testing to have configuration options
CRD_FILE=${CRD_FILE:-$SCRIPT_DIR/crds/couchbase.crds.yaml}
CHART_DIR=${CHART_DIR:-$SCRIPT_DIR}
OUTPUT_DIR=${OUTPUT_DIR:-$SCRIPT_DIR}
OUTPUT_VALUES_FILE=${OUTPUT_VALUES_FILE:-$OUTPUT_DIR/values.yaml}
OUTPUT_README_FILE=${OUTPUT_README_FILE:-$OUTPUT_DIR/README.md}

# First add the manually controlled source
cat "${SCRIPT_DIR}/values.yamltmpl" > "${OUTPUT_VALUES_FILE}"
# Now autogenerate the rest of the values file
CRD_FILE=${CRD_FILE} /bin/bash "${SCRIPT_DIR}/../tools/value-generation/generateValuesFile.sh" >> "${OUTPUT_VALUES_FILE}"
# Use this to generate the Markdown documentation
CHART_DIR=${CHART_DIR} /bin/bash "${SCRIPT_DIR}/../tools/value-generation/generateDocumentation.sh" > "${OUTPUT_README_FILE}"
