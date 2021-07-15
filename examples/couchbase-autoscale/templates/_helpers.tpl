{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "couchbase-autoscale.name" -}}
{{- $clustername := (index .Values "couchbase-operator" "cluster" "name") -}}
{{- default "couchbase-cluster" $clustername | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "couchbase-autoscale.bucket" -}}
{{- (index .Values "couchbase-operator" "buckets" "default" "name") -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "couchbase-autoscale.fullname" -}}
{{- printf "%s-%s" .Release.Name (include "couchbase-autoscale.name" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Generate cluster name from chart name or use user value
*/}}
{{- define "couchbase-autoscale.clustername" -}}
{{- $clustername := (index .Values "couchbase-operator" "cluster" "name") -}}
{{ default (include "couchbase-autoscale.fullname" .) $clustername }}
{{- end -}}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "couchbase-autoscale.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}
