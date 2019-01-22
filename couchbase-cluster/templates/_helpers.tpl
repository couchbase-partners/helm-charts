{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "couchbase-cluster.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "couchbase-cluster.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- if contains $name .Release.Name -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{/*
Cluster DNS name
*/}}
{{- define "couchbase-cluster.dns" -}}
  {{ printf "%s.%s" (include "couchbase-cluster.fullname" .) .Values.couchbaseCluster.dns.domain }}
{{- end -}}


{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "couchbase-cluster.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create the username of the Admin user.
TODO: Auto generate when there is a better mechanism for upgrading secrets
      https://github.com/pulumi/pulumi-kubernetes/issues/205
*/}}
{{- define "couchbase-cluster.username" -}}
  {{ .Values.couchbaseCluster.username | b64enc | quote }}
{{- end -}}

{{/*
Create the password of the Admin user.
TODO: Auto generate when there is a better mechanism for upgrading secrets
      https://github.com/pulumi/pulumi-kubernetes/issues/205
*/}}
{{- define "couchbase-cluster.password" -}}
  {{ .Values.couchbaseCluster.password | b64enc | quote }}
{{- end -}}


{{/*
Create secret for couchbase cluster.
*/}}
{{- define "couchbase-cluster.secret.name" -}}
{{- default (include "couchbase-cluster.fullname" .) .Values.couchbaseCluster.authSecretOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Generate cluster name from chart name or use user value
*/}}
{{- define "couchbase-cluster.clustername" -}}
  {{ default (include "couchbase-cluster.fullname" .) .Values.couchbaseCluster.name }}
{{- end -}}

{{/*
Name of tls operator secret
*/}}
{{- define  "couchbase-cluster.secret.tls-operator" -}}
{{- $fullname := printf "%s-operator-tls" (include "couchbase-cluster.fullname" .) -}}
{{- default $fullname .Values.couchbaseTLS.ServerSecret | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Name of tls server secret
*/}}
{{- define  "couchbase-cluster.secret.tls-server" -}}
{{- $fullname := printf "%s-server-tls" (include "couchbase-cluster.fullname" .) -}}
{{- default $fullname .Values.couchbaseTLS.ServerSecret | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Generate certificates for couchbase server
*/}}
{{- define "couchbase-cluster.gen-certs" -}}
{{- $clustername := (include "couchbase-cluster.clustername" .) -}}
{{- $altNames := list ( printf "*.%s.%s.svc" $clustername .Release.Namespace ) ( printf "*.%s" ( include "couchbase-cluster.dns" .) ) -}}
{{- $expiration := (.Values.couchbaseTLS.expiration | int) -}}
{{- $ca := genCA "couchbase-cluster-ca" $expiration -}}
{{- $caCert := default $ca.Cert .Values.couchbaseTLS.clusterSecret.caCert | b64enc -}}
{{- $cert := genSignedCert ( include "couchbase-cluster.fullname" . ) nil $altNames $expiration $ca -}}
{{- $clientCert := default $cert.Cert .Values.couchbaseTLS.operatorSecret.tlsCert | b64enc -}}
{{- $clientKey := default $cert.Key .Values.couchbaseTLS.operatorSecret.tlsKey | b64enc -}}
caCert: {{ $caCert }}
clientCert: {{ $clientCert }}
clientKey: {{ $clientKey }}
{{- end -}}
