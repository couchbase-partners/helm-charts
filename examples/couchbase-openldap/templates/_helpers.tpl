{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "couchbase-openldap.name" -}}
{{- $clustername := (index .Values "couchbase-operator" "cluster" "name") -}}
{{- default "couchbase-cluster" $clustername | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "couchbase-openldap.fullname" -}}
{{- printf "%s-%s" .Release.Name (include "couchbase-openldap.name" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Generate cluster name from chart name or use user value
*/}}
{{- define "couchbase-openldap.clustername" -}}
{{- $clustername := (index .Values "couchbase-operator" "cluster" "name") -}}
{{ default (include "couchbase-openldap.fullname" .) $clustername }}
{{- end -}}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "couchbase-openldap.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}
