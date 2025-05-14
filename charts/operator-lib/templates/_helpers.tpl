{{/*
Expand the name of the chart.
*/}}
{{- define "couchbase-lib.cluster.name" -}}
{{- default "couchbase-cluster" .Values.cluster.name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name
*/}}
{{- define "couchbase-lib.cluster.fullname" -}}
{{- printf "%s-%s" .Release.Name (include "couchbase-lib.cluster.name" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Generate cluster name from chart release or use user value.
If a cluster already exists using the "old" style of cluster name (lookup = k get couchbasecluster -n "<release.namespace>" "<deprecatedClusterName(from func)>"), use that name
Otherwise use the name from the chart values
*/}}
{{- define "couchbase-lib.cluster.clustername" -}}
{{- $deprecatedClusterName := (include "couchbase-lib.cluster.fullname" .) -}}
{{- $deprecatedClusterExists := (lookup "couchbase.com/v2" "CouchbaseCluster" .Release.Namespace $deprecatedClusterName) -}}
{{- if $deprecatedClusterExists -}}
{{ $deprecatedClusterName  }}
{{- else -}}
{{- (default .Release.Name .Values.cluster.name) }}
{{- end -}}
{{- end -}}