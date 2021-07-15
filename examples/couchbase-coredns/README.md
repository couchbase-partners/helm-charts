Deploying the Operator and CoreDNS 
===========================================

XDCR Involves connecting 2 couchbase clusters.
The steps here assume these clusters also exist on separate kubernetes clusters.
Refer to following documentation for changing between contexts:  https://kubernetes.io/docs/tasks/access-application-cluster/configure-access-multiple-clusters/

The inter-networking model is also assumed here: https://docs.couchbase.com/operator/current/tutorial-remote-dns.html

### On Remote Cluster
```bash
# Create remote namespace in remote cluster (having separate namespace also helps when testing locally)
kubectl create namespace remote

# Install couchbase in remote cluster
helm install destination -n remote couchbase/couchbase-operator

# Collect the remote configuration
helm template xnet . > remote_values.yaml
```

### On Local Cluster
```bash
# Create the coredns chart for network forwarding
# This chart is provided remote_values file which contains remote dns forwarding IP
helm install xnet -f remote_values.yaml stable/coredns

# Install couchbase helm chart with replication to remote cluster
helm install source -f remote_values .

# Load some data!
kubectl create -f travel_sample.yaml
```
