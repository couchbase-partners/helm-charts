#!/bin/bash
# Helper script to automatically provision a Kind cluster with a version of Kubernetes,
# install the helm chart and verify that works then repeat for all other versions.
#
set -u
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
CHART_DIR=${CHART_DIR:-$SCRIPT_DIR/../../couchbase-operator}
GENERATE_TEST=${GENERATE_TEST:-no}
OPERATOR_IMAGE=${OPERATOR_IMAGE:-couchbase/couchbase-operator:v1}
DAC_IMAGE=${DAC_IMAGE:-couchbase/couchbase-operator-admission:v1}
SERVER_IMAGE=${SERVER_IMAGE:-couchbase/server:6.6.2}

declare -a SUPPORTED_K8S_VERSIONS=('v1.17.11' 'v1.18.8' 'v1.19.1' 'v1.20.0' )

# Remove all existing KIND clusters
kind delete clusters --all

# Run for each version and carry on, exit at end with relevant error code (if any)
# The user can connect to any left running to debug with a version-specific kube-config file.
exitCode=0
for K8S_VERSION in "${SUPPORTED_K8S_VERSIONS[@]}"; do
    echo "Testing $K8S_VERSION"

    # Create the test cluster
    kind create cluster --name "${K8S_VERSION}" --image kindest/node:"${K8S_VERSION}" --kubeconfig kubeconfig."${K8S_VERSION}"

    # Optionally generate the chart
    if [[ "${GENERATE_TEST}" == "yes" ]]; then
        if [[ -f "${CHART_DIR}/generate.sh" ]]; then
            MIN_K8S_VERSION=$(echo "$K8S_VERSION"|cut -d'.' -f 2) /bin/bash "${CHART_DIR}/generate.sh"
        else 
            echo "FAILED: No generate script at: ${CHART_DIR}/generate.sh"
        fi
    fi

    # Load any local images we may want into the cluster by default (if they exist locally)
    [[ -n $(docker images -q "${OPERATOR_IMAGE}" 2> /dev/null) ]] &&    kind load docker-image "${OPERATOR_IMAGE}" --name "${K8S_VERSION}"
    [[ -n $(docker images -q "${DAC_IMAGE}" 2> /dev/null) ]] &&         kind load docker-image "${DAC_IMAGE}" --name "${K8S_VERSION}"
    [[ -n $(docker images -q "${SERVER_IMAGE}" 2> /dev/null) ]] &&      kind load docker-image "${SERVER_IMAGE}" --name "${K8S_VERSION}"

    # Run a helm install to confirm
    # Call this script with `-f ./image-values.yaml` for example to pass in overrides
    if helm upgrade --kubeconfig kubeconfig."${K8S_VERSION}" --install --debug --wait couchbase "${CHART_DIR}" "$@" ; then
        echo "PASSED: $K8S_VERSION"
        kind delete cluster --name "${K8S_VERSION}"
        rm -f kubeconfig."${K8S_VERSION}"
    else 
        echo "FAILED: $K8S_VERSION"
        exitCode=1
    fi
done

exit $exitCode