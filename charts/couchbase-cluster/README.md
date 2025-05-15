This chart can be used to deploy a couchbase cluster and associated resources. A couchbse operator must be running in the same namespace in order for this chart to work.

For the timebeing, a bucket backup service account with generic names will be installed by default

TODO - these need to be changed to use name declartions or release pre/postfix'ed resource names to avoid clashes with other resources

To install two clusters:

helm install c1 ./couchbase-cluster --set cluster.backup.managed=false --set buckets.default=null
helm install c2 ./couchbase-cluster --set cluster.backup.managed=false --set buckets.default=null