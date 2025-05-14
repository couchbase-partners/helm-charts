{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "sync-gateway.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Generate name of sync gateway
*/}}
{{- define "sync-gateway.name" -}}
{{- printf "sync-gateway-%s" (include "couchbase-lib.cluster.name" .) -}}
{{- end -}}

{{/*
Generate sync gateway url scheme
*/}}
{{- define "sync-gateway.scheme" -}}
{{- $clustername := (include "sync-gateway.name" .RootScope) -}}
{{- if and .RootScope.Values.syncGateway.networking.tls.enabled .RootScope.Values.syncGateway.networking.dns -}}
{{/*
When TLS enabled and the full dns name is provided, always use secure transport
*/}}
{{- printf "couchbases://console.%s" .RootScope.Values.syncGateway.networking.dns.domain -}}
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
{{- define "sync-gateway.json-config" -}}
{{/*
Derive config
*/}}
{{- $rootScope := . -}}
{{- $cluster := .Values.syncGateway.cluster -}}
{{- $config := .Values.syncGateway.config }}
{{- range $i, $db := $config.databases }}
	{{- $username := (default $cluster.username $db.username) -}}
	{{- $password := (default $cluster.password $db.password) -}}
	{{- $server := default (include "sync-gateway.scheme" (dict "RootScope" $rootScope)) $db.server -}}
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
{{- define "sync-gateway.secret" -}}
{{- default (include "sync-gateway.name" .) .Values.syncGateway.configSecret -}}
{{- end -}}

{{/*
Get name of external sync gateway to use name for dns
*/}}
{{- define "sync-gateway.externalname" -}}
{{- printf "mobile.%s"  .Values.networking.dns.domain -}}
{{- end -}}

{{/*
Sets sync-gateway pod dns config based on coredns values
*/}}
{{- define "sync-gateway.pod-dnsconfig" -}}
{{- if .Values.syncGateway.coredns.service -}}
{{- $dnsConfig := dict -}}
{{- $_ := set $dnsConfig "nameservers" (list (lookup "v1" "Service" .Release.Namespace .Values.syncGateway.coredns.service).spec.clusterIP) -}}
{{- $_ := set $dnsConfig "searches" .Values.syncGateway.coredns.searches -}}
{{- $_ := set .Config "dnsConfig" $dnsConfig -}}
{{- $_ := set .Config "dnsPolicy" "None" -}}
{{- end -}}
{{- end -}}