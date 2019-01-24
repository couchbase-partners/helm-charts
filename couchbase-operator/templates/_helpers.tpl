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
{{- $name := default .Values.couchbaseOperator.name .Values.nameOverride -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "admission-controller.fullname" -}}
{{- $name := default .Values.admissionController.name  .Values.nameOverride -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "couchbase-operator.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create the name of the couchbase-operator service account to use
*/}}
{{- define "couchbase-operator.serviceAccountName" -}}
{{- if .Values.serviceAccount.couchbaseOperator.create -}}
    {{- $defaultSA := default (include "couchbase-operator.fullname" .) .Values.serviceAccount.couchbaseOperator.name -}}
    {{ default $defaultSA .Values.couchbaseOperator.serviceAccountName }}
{{- else -}}
    {{ default "default" .Values.couchbaseOperator.serviceAccountName }}
{{- end -}}
{{- end -}}

{{/*
Get kind of rbac role to use based on requested level of access
*/}}
{{- define "couchbase-operator.rbacRole" -}}
{{- if .Values.rbac.clusterRoleAccess -}}
{{- printf "ClusterRole" }}
{{- else -}}
{{- printf "Role" }}
{{- end -}}
{{- end -}}

{{/*
Create the name of the admission-controller service account to use.
This value may be overriden by the serviceAccountName in the controller
*/}}
{{- define "admission-controller.serviceAccountName" -}}
{{- if .Values.serviceAccount.admissionController.create -}}
    {{- $defaultSA := default (include "admission-controller.fullname" .) .Values.serviceAccount.admissionController.name -}}
    {{ default $defaultSA .Values.admissionController.serviceAccountName }}
{{- else -}}
    {{ default "default" .Values.admissionController.serviceAccountName }}
{{- end -}}
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
{{- default (include "admission-controller.fullname" .) .Values.admissionTLS.secret.name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Generate certificates for admission-controller webhooks
*/}}
{{- define "admission-controller.gen-certs" -}}
{{- $altNames := list ( include "admission-controller.service.fullname" . ) -}}
{{- $expiration := (.Values.admissionTLS.expiration | int) -}}
{{- $ca := genCA "admission-controller-ca" $expiration -}}
{{- $caCert := default $ca.Cert .Values.admissionTLS.webhookCa | b64enc -}}
{{- $cert := genSignedCert ( include "admission-controller.fullname" . ) nil $altNames $expiration $ca -}}
{{- $clientCert := default $cert.Cert .Values.admissionTLS.secret.tlsCert | b64enc -}}
{{- $clientKey := default $cert.Key .Values.admissionTLS.secret.tlsKey | b64enc -}}
caCert: {{ $caCert }}
clientCert: {{ $clientCert }}
clientKey: {{ $clientKey }}
{{- end -}}
