{{/*
Expand the name of the chart.
*/}}
{{- define "mysql-chart.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name. Uses Release.Name for cleaner resource names.
*/}}
{{- define "mysql-chart.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "mysql-chart.labels" -}}
helm.sh/chart: {{ .Chart.Name }}-{{ .Chart.Version | replace "+" "_" }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}

{{/*
Backup component labels
*/}}
{{- define "mysql-chart.backup.labels" -}}
{{- include "mysql-chart.labels" . | nindent 0 }}
app.kubernetes.io/name: {{ include "mysql-chart.fullname" . }}-backup
app.kubernetes.io/component: backup
{{- end -}}
