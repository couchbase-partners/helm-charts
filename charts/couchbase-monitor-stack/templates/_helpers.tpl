{{/* vim: set filetype=mustache: */}}
{{/*
Name chart after an existing cluster.
*/}}
{{- define "couchbase-monitor-stack.clustername" -}}
{{- $clusters := (lookup "couchbase.com/v2" "CouchbaseCluster" "" "").items -}}
{{- if $clusters -}}
{{- default "%s" (first $clusters).metadata.name .Values.clusterName -}}
{{- else -}}
{{- default "cb-example" .Values.clusterName -}}
{{- end -}}
{{- end -}}

{{- define "couchbase-monitor-stack.bucket" -}}
{{- $buckets := (lookup "couchbase.com/v2" "CouchbaseBucket" "" "").items -}}
{{- if $buckets -}}
{{- printf "%s" (first $buckets).metadata.name -}}
{{- else -}}
{{- default "default" .Values.bucketName -}}
{{- end -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "couchbase-monitor-stack.fullname" -}}
{{- printf "%s-%s" .Release.Name (include "couchbase-monitor-stack.clustername" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "couchbase-monitor-stack.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}
