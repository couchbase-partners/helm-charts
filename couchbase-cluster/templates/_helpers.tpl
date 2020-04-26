{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "couchbase-cluster.name" -}}
{{- default .Chart.Name .Values.cluster.name | trunc 63 | trimSuffix "-" -}}
{{- end -}}


{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "couchbase-cluster.fullname" -}}
{{- printf "%s-%s" .Release.Name (include "couchbase-cluster.name" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}


{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "couchbase-cluster.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create the username of the Admin user.
*/}}
{{- define "couchbase-cluster.username" -}}
  {{ .Values.cluster.security.username | b64enc | quote }}
{{- end -}}

{{/*
Create the password of the Admin user.
*/}}
{{- define "couchbase-cluster.password" -}}
{{- if not .Values.cluster.security.password  -}}
{{/*
   Attempt to reuse current password
*/}}
{{- $secret := (lookup "v1" "Secret" .Release.Namespace (include "couchbase-cluster.fullname" .)) -}}
{{- if $secret -}}
{{-  $_ := set .Values.cluster.security "password" (b64dec $secret.data.password) -}}
{{- else -}}
{{/*
	Setting random password
*/}}
{{-  $_ := set .Values.cluster.security "password" (b64enc (randAlpha 6)) -}}
{{- end -}}
{{- end -}}
{{ .Values.cluster.security.password | b64enc | quote }}
{{- end -}}


{{/*
Create secret for couchbase cluster.
*/}}
{{- define "couchbase-cluster.admin-secret" -}}
{{- default (include "couchbase-cluster.fullname" .) .Values.cluster.security.adminSecret | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Generate cluster name from chart name or use user value
*/}}
{{- define "couchbase-cluster.clustername" -}}
  {{ default (include "couchbase-cluster.fullname" .) .Values.cluster.name }}
{{- end -}}

{{/*
Determine if tls is enabled for cluster
*/}}
{{- define  "couchbase-cluster.tls.enabled" -}}
{{- if or .Values.cluster.tls .Values.tls.generate -}}
{{- true -}}
{{- else -}}
{{- end -}}
{{- end -}}

{{/*
Name of tls operator secret
*/}}
{{- define  "couchbase-cluster.tls.operator-secret" -}}
{{- if .Values.cluster.tls -}}
{{- .Values.cluster.tls.static.serverSecret -}}
{{- else -}}
{{- (printf "%s-operator-tls" (include "couchbase-cluster.fullname" .)) | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}

{{/*
Name of tls server secret
*/}}
{{- define  "couchbase-cluster.tls.server-secret" -}}
{{- if .Values.cluster.tls -}}
{{- .Values.cluster.tls.static.operatorSecret -}}
{{- else -}}
{{- (printf "%s-server-tls" (include "couchbase-cluster.fullname" .)) | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}

{{/*
Generate certificates for couchbase-cluster
*/}}
{{- define "couchbase-cluster.tls" -}}
{{- $serverSecret := (lookup "v1" "Secret" .Release.Namespace (include "couchbase-cluster.tls.server-secret" .)) -}}
{{- $operatorSecret := (lookup "v1" "Secret" .Release.Namespace (include "couchbase-cluster.tls.operator-secret" .)) -}}
{{- if (and $serverSecret $operatorSecret) -}}
caCert: {{ index $operatorSecret.data "ca.crt" }}
clientCert: {{ index $serverSecret.data "chain.pem" }}
clientKey: {{ index $serverSecret.data "pkey.key" }}
{{- else -}}
{{- $expiration := (.Values.tls.expiration | int) -}}
{{- $ca :=  genCA "couchbase-cluster-ca" $expiration -}}
{{- template "couchbase-cluster.tls.generate-certs" (dict "RootScope" . "CA" $ca) -}}
{{- end -}}
{{- end -}}

{{/*
Generate client key and cert from CA
*/}}
{{- define "couchbase-cluster.tls.generate-certs" -}}
{{- $clustername := (include "couchbase-cluster.clustername" .RootScope) -}}
{{- $altNames :=  list "localhost" (printf "*.%s.%s.svc" $clustername .RootScope.Release.Namespace) (printf "*.%s.%s" $clustername .RootScope.Release.Namespace) (printf "*.%s" $clustername) (printf "*.%s-srv.%s.svc" $clustername .RootScope.Release.Namespace) (printf "*.%s-srv.%s" $clustername .RootScope.Release.Namespace) (printf "*.%s-srv" $clustername) (printf "%s-srv.%s.svc" $clustername .RootScope.Release.Namespace) (printf "%s-srv.%s" $clustername .RootScope.Release.Namespace) (printf "%s-srv" $clustername) -}}
{{- if .RootScope.Values.cluster.networking.dns -}}
{{- $extendedAltNames := append $altNames (printf "*.%s"  .RootScope.Values.cluster.networking.dns.domain) -}}
{{- template "couchbase-cluster.tls.sign-certs" (dict "RootScope" .RootScope "CA" .CA "AltNames" $extendedAltNames) -}}
{{- else -}}
{{- template "couchbase-cluster.tls.sign-certs" (dict "RootScope" .RootScope "CA" .CA "AltNames" $altNames) -}}
{{- end -}}
{{- end -}}

{{/*
Generate signed client key and cert from CA and altNames
*/}}
{{- define "couchbase-cluster.tls.sign-certs" -}}
{{- $expiration := (.RootScope.Values.tls.expiration | int) -}}
{{- $cert := genSignedCert ( include "couchbase-cluster.fullname" .RootScope) nil .AltNames $expiration .CA -}}
caCert: {{ .CA.Cert | b64enc }}
clientCert: {{ $cert.Cert  | b64enc }}
clientKey: {{ $cert.Key | b64enc }}
{{- end -}}

{{/*
Generate name of sync gateway
*/}}
{{- define "couchbase-cluster.sg.name" -}}
{{- $name := printf "sync-gateway-%s" (include "couchbase-cluster.clustername" .) -}}
{{- default  $name .Values.syncGateway.name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Generate sync gateway url scheme
*/}}
{{- define "couchbase-cluster.sg.scheme" -}}
{{- $clustername := (include "couchbase-cluster.clustername" .RootScope) -}}
{{- if (include "couchbase-cluster.tls.enabled" .RootScope) -}}
{{/*
When TLS enabled, always use secure transport and also full dns name if provided
*/}}
{{- if .RootScope.Values.cluster.networking.dns }}
{{- printf "couchbases://console.%s" .RootScope.Values.cluster.networking.dns.domain -}}
{{- else -}}
{{- printf "couchbases://%s-srv.%s" $clustername .RootScope.Release.Namespace -}}
{{- end -}}
{{- else -}}
{{/*
Non TLS, always use plain text transport with internal service dns
*/}}
{{- printf "couchbase://%s-srv.%s" $clustername .RootScope.Release.Namespace -}}
{{- end -}}
{{- end -}}

{{/*
Generate sync gateway config as json
*/}}
{{- define "couchbase-cluster.sg.json-config" -}}
{{/*
Ensure password is set/generated
*/}}
{{- $_ := (include "couchbase-cluster.password" .) -}}
{{/*
Derive config
*/}}
{{- $rootScope := . -}}
{{- $cluster := .Values.cluster -}}
{{- $config := .Values.syncGateway.config }}
{{- range $db := $config.databases }}
	{{- $username := (default $cluster.security.username $db.username) -}}
	{{- $password := (default $cluster.security.password $db.password) -}}
	{{- $server := default (include "couchbase-cluster.sg.scheme" (dict "RootScope" $rootScope)) $db.server -}}
  {{- $db := set $db "username" $username -}}
  {{- $db := set $db "password" $password -}}
  {{- $db := set $db "server" $server -}}
  {{- if (include "couchbase-cluster.tls.enabled" .RootScope) -}}
  {{- $db := set $db "cacertpath" "/etc/sync_gateway/ca.pem" -}}
  {{- end -}}
{{- end -}}
{{- $config | toJson -}}
{{- end -}}

{{/*
Get name of secret to use for sync gateway
*/}}
{{- define "couchbase-cluster.sg.secret" -}}
{{- default (include "couchbase-cluster.sg.name" .) .Values.syncGateway.configSecret -}}
{{- end -}}

{{/*
Get name of external sync gateway to use name for dns
*/}}
{{- define "couchbase-cluster.sg.externalname" -}}
{{- printf "mobile.%s"  .Values.cluster.networking.dns.domain -}}
{{- end -}}

{{/*
Generate name of service account to use for backups
*/}}
{{- define "couchbase-cluster.backup.service-account" -}}
{{- $clusterName := (include "couchbase-cluster.clustername" .) -}}
{{- default (printf "backup-%s" $clusterName) .Values.cluster.serviceAccountName -}}
{{- end -}}
