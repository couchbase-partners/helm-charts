Deploying the Operator and Couchbase Server
===========================================

### REQUIRED
* [Helm 3.1+](https://github.com/helm/helm/releases) is required when installing the couchbase cluster chart.

### Quick Start
Two Helm charts are available for deploying Couchbase. The Couchbase Operator
Chart deploys the admission controller and the Operator itself.
The Couchbase Cluster chart deploys the Couchbase Server cluster.

For production deployments, you’ll only use the Operator Chart. For
development environments, the Couchbase Cluster Chart is available to
help you quickly set up a test cluster.

To quickly deploy the admission controller and Operator, as well as a
Couchbase Server cluster:

1.  Add the chart repository to `helm`:

        helm repo add couchbase https://couchbase-partners.github.io/helm-charts/

2.  Install the Operator Chart:

        helm install couchbase/couchbase-operator

3.  Install the Couchbase Cluster Chart:

        helm install couchbase/couchbase-cluster


See Couchbase Helm [Documentation](https://docs.couchbase.com/operator/current/helm-setup-guide.html)
for more information about customizing and managing your charts.
