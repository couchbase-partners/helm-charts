{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "couchbase-coredns.name" -}}
{{- $clustername := (index .Values "couchbase-operator" "cluster" "name") -}}
{{- default "couchbase-cluster" $clustername | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "couchbase-coredns.fetch-remote.dns" -}}
{{- $endpoints := (lookup "v1" "Endpoints" .Values.remote.dns.namespace .Values.remote.dns.endpoint) -}}
{{- $addresses := (index $endpoints.subsets 0).addresses -}}
{{- (index $addresses 0).ip -}}
{{- end -}}

{{- define "couchbase-coredns.local-dns" -}}
{{- $service := (lookup "v1" "Service" .Values.local.dns.namespace .Values.local.dns.service) -}}
{{- $service.spec.clusterIP -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "couchbase-coredns.fullname" -}}
{{- printf "%s-%s" .Release.Name (include "couchbase-coredns.name" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Generate cluster name from chart name or use user value
*/}}
{{- define "couchbase-coredns.clustername" -}}
{{- $clustername := (index .Values "couchbase-operator" "cluster" "name") -}}
{{ default (include "couchbase-coredns.fullname" .) $clustername }}
{{- end -}}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "couchbase-coredns.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Collects uuid from remote cluster
*/}}
{{- define "couchbase-coredns.fetch-remote.uuid" -}}
{{- $cluster := (lookup "couchbase.com/v2" "CouchbaseCluster" .Values.remote.couchbase.namespace .Values.remote.couchbase.name) -}}
{{- $cluster.status.clusterId -}}
{{- end -}}

{{/*
Generates name of remote cluster
*/}}
{{- define "couchbase-coredns.fetch-remote.hostname" -}}
{{- .Values.remote.couchbase.name -}}.{{- .Values.remote.couchbase.namespace -}}
{{- end -}}

{{/*
Collects username to authenticate with remote cluster
*/}}
{{- define "couchbase-coredns.fetch-remote.auth.username" -}}
{{- $secret := (lookup "v1" "Secret" .Values.remote.couchbase.namespace .Values.remote.couchbase.name) -}}
{{- $secret.data.username -}}
{{- end -}}

{{/*
Collects username to authenticate with remote cluster
*/}}
{{- define "couchbase-coredns.fetch-remote.auth.password" -}}
{{- $secret := (lookup "v1" "Secret" .Values.remote.couchbase.namespace .Values.remote.couchbase.name) -}}
{{- $secret.data.password -}}
{{- end -}}
