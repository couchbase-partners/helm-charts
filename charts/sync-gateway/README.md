# Couchbase Sync Gateway Helm Chart

This Helm chart deploys Couchbase Sync Gateway on Kubernetes.

## Installation

### Add the Couchbase Helm Repository

This branch/chart is a prototype that separates the Helm chart dependency into its own chart and uses it as a subchart inside the `couchbase-operator`.

### To Run as part of the couchbase-operator chart (Locally in a Dev Environment)

1. Navigate into the `couchbase-operator` chart directory and build the dependencies:

   `helm dependency build`

2. Return to the `/charts` directory and install the chart:

   `helm install <release> ./couchbase-operator --set install.couchbaseOperator=false --set install.admissionController=false --set install.couchbaseCluster=true --set install.syncGateway=true`

**Note:**

- Toggle the appropriate flags to enable other components.
- Sync Gateway values must be manually configured.
