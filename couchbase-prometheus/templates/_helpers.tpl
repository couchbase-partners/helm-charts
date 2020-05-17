{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "couchbase-prometheus.name" -}}
{{- $clustername := (index .Values "couchbase-operator" "cluster" "name") -}}
{{- default "couchbase-cluster" $clustername | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "couchbase-prometheus.fullname" -}}
{{- printf "%s-%s" .Release.Name (include "couchbase-prometheus.name" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Generate cluster name from chart name or use user value
*/}}
{{- define "couchbase-prometheus.clustername" -}}
{{- $clustername := (index .Values "couchbase-operator" "cluster" "name") -}}
{{ default (include "couchbase-prometheus.fullname" .) $clustername }}
{{- end -}}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "couchbase-prometheus.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}
