Deploying the Operator and Couchbase Server
===========================================

### REQUIRED
* [Helm 3.1+](https://github.com/helm/helm/releases) is required when installing the couchbase cluster chart.
*  A license for Couchbase Server Enterprise Edition.

### Quick Start
The Couchbase Operator can be used to instantly deploy the Autonomous Operator, Admission Controller, and Couchbase Cluster.
Additonally, Sync Gateway can be deployed, along with auto-generation of TLS and networking services.

To quickly deploy the admission controller and Operator, as well as a
Couchbase Server cluster:

1.  Add the chart repository to `helm`:

        helm repo add couchbase https://couchbase-partners.github.io/helm-charts/
        helm repo update

2.  Install the Chart:

        helm install default couchbase/couchbase-operator


See Couchbase Helm [Documentation](https://docs.couchbase.com/operator/current/helm-setup-guide.html)
for more information about customizing and managing your charts.
