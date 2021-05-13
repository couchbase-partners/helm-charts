#!/bin/bash
# Helper script to automatically provision a Kind cluster with a version of Kubernetes,
# install the helm chart and verify that works then repeat for all other versions.
set -u
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
CHART_DIR=${CHART_DIR:-$SCRIPT_DIR/../../couchbase-operator}

declare -a SUPPORTED_K8S_VERSIONS=('v1.17.11' 'v1.18.8' 'v1.19.1' 'v1.20.0' )

kind delete clusters --all

exitCode=0
for K8S_VERSION in "${SUPPORTED_K8S_VERSIONS[@]}"; do
    echo "Testing $K8S_VERSION"
    kind create cluster --name "${K8S_VERSION}" --image kindest/node:"${K8S_VERSION}" --kubeconfig kubeconfig."${K8S_VERSION}"
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