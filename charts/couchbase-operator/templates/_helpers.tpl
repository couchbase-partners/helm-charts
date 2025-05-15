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