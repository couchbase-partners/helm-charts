{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "couchbase-operator.name" -}}
{{- default .Chart.Name .Values.couchbaseOperator.name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Admission operator name
*/}}
{{- define "admission-controller.name" -}}
{{- default .Chart.Name .Values.admissionController.name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "couchbase-operator.fullname" -}}
{{- printf "%s-%s" .Release.Name .Values.couchbaseOperator.name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "admission-controller.fullname" -}}
{{- printf "%s-%s" .Release.Name .Values.admissionController.name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "couchbase-operator.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create service name for admission service from chart name or apply override.
*/}}
{{- define "admission-controller.service.name" -}}
{{- default (include "admission-controller.fullname" .) .Values.admissionService.name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create service fullname for admission service with namespace as domain.
*/}}
{{- define "admission-controller.service.fullname" -}}
{{- default ( printf "%s.%s.svc" (include "admission-controller.service.name" .) .Release.Namespace ) -}}
{{- end -}}


{{/*
Create secret for admission operator.
*/}}
{{- define "admission-controller.secret.name" -}}
  {{- default (include "admission-controller.fullname" .) .Values.admissionSecret.name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Generate certificates for admission-controller webhooks
*/}}
{{- define "admission-controller.gen-certs" -}}
{{/* reusing old certs if exist */}}
{{- $secret := (lookup "v1" "Secret" .Release.Namespace (include "admission-controller.secret.name" .)) -}}
{{- $webhook := (lookup "admissionregistration.k8s.io/v1" "ValidatingWebhookConfiguration" .Release.Namespace (include "admission-controller.fullname" .)) -}}
{{- if and $secret $webhook -}}
clientCert: {{ index $secret.data "tls-cert-file" }}
clientKey: {{ index $secret.data "tls-private-key-file" }}
caCert: {{ (first $webhook.webhooks).clientConfig.caBundle }}
{{- else -}}
{{/* generate new certs to use */}}
{{- $expiration := (.Values.admissionCA.expiration | int) -}}
{{- if (or (empty .Values.admissionCA.cert) (empty .Values.admissionCA.key)) -}}
{{- $ca :=  genCA "admission-controller-ca" $expiration -}}
{{- template "admission-controller.gen-client-tls" (dict "RootScope" . "CA" $ca) -}}
{{- else -}}
{{- $ca :=  buildCustomCert (.Values.admissionCA.cert | b64enc) (.Values.admissionCA.key | b64enc) -}}
{{- template "admission-controller.gen-client-tls" (dict "RootScope" . "CA" $ca) -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{/*
Generate client key and cert from CA
*/}}
{{- define "admission-controller.gen-client-tls" -}}
{{- $altNames := list ( include "admission-controller.service.fullname" .RootScope) -}}
{{- $expiration := (.RootScope.Values.admissionCA.expiration | int) -}}
{{- $cert := genSignedCert ( include "admission-controller.fullname" .RootScope) nil $altNames $expiration .CA -}}
{{- $clientCert := default $cert.Cert .RootScope.Values.admissionSecret.cert | b64enc -}}
{{- $clientKey := default $cert.Key .RootScope.Values.admissionSecret.key | b64enc -}}
caCert: {{ .CA.Cert | b64enc }}
clientCert: {{ $clientCert }}
clientKey: {{ $clientKey }}
{{- end -}}

{{/*
====================  Cluster ====================
*/}}
{{/*
Expand the name of the chart.
*/}}
{{- define "couchbase-cluster.name" -}}
{{- default "couchbase-cluster" .Values.cluster.name | trunc 63 | trimSuffix "-" -}}
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
{{- default (printf "auth-%s" (include "couchbase-cluster.fullname" .)) .Values.cluster.security.adminSecret | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Generate cluster name from chart name or use user value
*/}}
{{- define "couchbase-cluster.clustername" -}}
  {{ default (include "couchbase-cluster.fullname" .) .Values.cluster.name }}
{{- end -}}


{{/*
Generate cluster spec
*/}}
{{- define "couchbase-cluster.spec" -}}
{{- $spec := .Values.cluster -}}
{{- $security := get $spec "security" -}}
{{- $security := set $security "adminSecret" (include "couchbase-cluster.admin-secret" .) -}}
{{- $security := unset $security "password" -}}
{{- $security := unset $security "username" -}}

{{/*
Transform servers from map to list
*/}}
{{- $servers := list -}}

{{- $rootscope := . -}}
{{- range $server, $config := $spec.servers -}}

{{/*
Ignoring provided entries that are not maps
*/}}
{{- if typeIs "map[string]interface {}" $config -}}
{{- if $config.pod -}}
{{/*
Apply dns configuration to the config if specified since environments
using coredns settings will need to apply settings to Pod (so user doesn't have to copy manually).
This performs an in-place modification of the $config map.
*/}}
{{- template "couchbase-cluster.pod-dnsconfig" (dict "RootScope" $rootscope "Config" $config.pod.spec) }}
{{- end }}
{{/*
Apply config name and append to server list
*/}}
{{- $config := set $config "name" $server -}}
{{- $servers = append $servers $config -}}
{{- end -}}
{{- end -}}

{{/*
Produce cluster config
*/}}
{{- $spec := set $spec "servers" $servers  -}}
{{- toYaml $spec | indent 2 -}}
{{- end -}}



{{/*
Sets pod dns config based on coredns values
*/}}
{{- define "couchbase-cluster.pod-dnsconfig" -}}
{{- if .RootScope.Values.coredns.service -}}
{{- $dnsConfig := dict -}}
{{- $_ := set $dnsConfig "nameservers" (list (lookup "v1" "Service" .RootScope.Release.Namespace .RootScope.Values.coredns.service).spec.clusterIP) -}}
{{- $_ := set $dnsConfig "searches" .RootScope.Values.coredns.searches -}}
{{- $_ := set .Config "dnsConfig" $dnsConfig -}}
{{- $_ := set .Config "dnsPolicy" "None" -}}
{{- end -}}
{{- end -}}

{{/*
Determine if tls is enabled for cluster
*/}}
{{- define  "couchbase-cluster.tls.enabled" -}}
{{- if or .Values.cluster.networking.tls .Values.tls.generate -}}
{{- true -}}
{{- else -}}
{{- end -}}
{{- end -}}

{{/*
Get nodeToNodeEncryption value
*/}}
{{- define  "couchbase-cluster.tls.nodeEncryption" -}}
{{/* Prioritize cluster.tls */}}
{{- if .Values.cluster.networking.tls  -}}
{{- default "" .Values.cluster.networking.tls.nodeToNodeEncryption -}}
{{- else -}}
{{/* Fallback to top-level tls */}}
{{- default "" .Values.tls.nodeToNodeEncryption -}}
{{- end -}}
{{- end -}}

{{/*
Name of tls operator secret
*/}}
{{- define  "couchbase-cluster.tls.operator-secret" -}}
{{- if .Values.cluster.networking.tls -}}
{{- .Values.cluster.networking.tls.static.operatorSecret -}}
{{- else -}}
{{- (printf "%s-operator-tls" (include "couchbase-cluster.fullname" .)) | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}

{{/*
Name of tls server secret
*/}}
{{- define  "couchbase-cluster.tls.server-secret" -}}
{{- if .Values.cluster.networking.tls -}}
{{- .Values.cluster.networking.tls.static.serverSecret -}}
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
{{- $altNames :=  list "localhost" (printf "*.%s.%s.svc" $clustername .RootScope.Release.Namespace) (printf "*.%s.%s" $clustername .RootScope.Release.Namespace) (printf "*.%s" $clustername) (printf "*.%s-srv.%s.svc" $clustername .RootScope.Release.Namespace) (printf "*.%s-srv.%s" $clustername .RootScope.Release.Namespace) (printf "*.%s-srv" $clustername) (printf "%s-srv.%s.svc" $clustername .RootScope.Release.Namespace) (printf "%s-srv.%s" $clustername .RootScope.Release.Namespace) (printf "%s-srv" $clustername) (printf "*.%s-srv.%s.svc.cluster.local" $clustername .RootScope.Release.Namespace) (printf "host.%s.%s.svc.cluster.local" $clustername .RootScope.Release.Namespace) -}}
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
{{- range $i, $db := $config.databases }}
	{{- $username := (default $cluster.security.username $db.username) -}}
	{{- $password := (default $cluster.security.password $db.password) -}}
	{{- $server := default (include "couchbase-cluster.sg.scheme" (dict "RootScope" $rootScope)) $db.server -}}
  {{- $db := set $db "username" $username -}}
  {{- $db := set $db "password" $password -}}
  {{- $db := set $db "server" $server -}}
  {{- if $db.cacert }}
  {{- $db := set $db "cacertpath" (printf "/etc/sync_gateway/ca.%s.pem" $i) -}}
  {{- end -}}
  {{- $db := unset $db "cacert" -}}
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

{{/*
Apply default to rbac bucket role
*/}}
{{- define "couchbase-cluster.rbac.apply-default" -}}
{{- $bucketRoleList := list "bucket_admin" "views_admin" "fts_admin"  "bucket_full_access" "data_reader" "data_writer" "data_dcp_reader" "data_backup" "data_monitoring" "replication_target" "analytics_manager" "views_reader" "fts_searcher" "query_select" "query_update" "query_insert" "query_delete" "query_manage_index" -}}
{{- println "- name: " .name -}}
{{- if (has .name $bucketRoleList) -}}
{{- if (not .bucket) -}}
{{- println "  bucket: " ("*" | quote) -}}
{{- else -}}
{{- println "  bucket: " .bucket -}}
{{- end -}}
{{- end -}}
{{- end -}}

