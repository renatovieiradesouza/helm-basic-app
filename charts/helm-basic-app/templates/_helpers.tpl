{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "basic-deployment.name" -}}
{{- default .Release.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "basic-deployment.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "basic-deployment.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "basic-deployment.labels" -}}
helm.sh/chart: {{ include "basic-deployment.chart" . }}
{{ include "basic-deployment.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "basic-deployment.selectorLabels" -}}
app: {{ include "basic-deployment.name" . }}
app.kubernetes.io/name: {{ include "basic-deployment.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "basic-deployment.serviceAccountName" -}}
  {{- if .Values.serviceAccount }}
    {{- if .Values.serviceAccount.create }}
      {{- default (include "basic-deployment.fullname" .) .Values.serviceAccount.name }}
    {{- else }}
      {{- default "default" .Values.serviceAccount.name }}
    {{- end }}
  {{- else -}}
    "default"
  {{- end }}
{{- end }}

{{/*
Generate environment variables
*/}}
{{- define "basic-deployment.env" -}}
{{- if .Values.env }}
env:
  {{- toYaml .Values.env | nindent 2 }}
{{- end }}
{{- end }}

{{/*
Generate envFrom configuration
*/}}
{{- define "basic-deployment.envFrom" -}}
{{- if .Values.envFrom }}
envFrom:
{{- if .Values.envFrom.configMaps }}
{{- range $i, $v := .Values.envFrom.configMaps }}
{{- if $v.data }}
- configMapRef:
    name: {{ include "basic-deployment.name" $ }}-config-env-{{ default $i $v.name }}
    optional: {{ default false $v.optional }}
{{ else if $v.name }}
- configMapRef:
    name: {{ $v.name }}
    optional: {{ default false $v.optional }}
{{- end }}
{{- end }}
{{- end }}
{{- if .Values.envFrom.secrets }}
{{- range $i, $v := .Values.envFrom.secrets }}
{{- if $v.data }}
- secretRef:
    name: {{ include "basic-deployment.name" $ }}-secret-env-{{ default $i $v.name }}
    optional: {{ default false $v.optional }}
{{ else if $v.name }}
- secretRef:
    name: {{ $v.name }}
    optional: {{ default false $v.optional }}
{{- end }}
{{- end }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Generate volume mounts
*/}}
{{- define "basic-deployment.volumeMounts" -}}
volumeMounts:
{{- if and .Values.volumesMount.enabled }}
- mountPath: "/config"
  name: {{ .Release.Name }}-apps-config
{{- end }}
{{- if and .Values.secret.enabled (not (eq .Values.secret.mountPath "")) }}
- mountPath: {{ .Values.secret.mountPath }}
  name: {{ .Release.Name }}-secret
{{- end }}
{{- range $i, $v := .Values.existingSecrets }}
{{- if and ( default "" $v.mountPath ) ( default "" $v.secretName ) }}
- mountPath: {{ $v.mountPath }}
  name: {{ $v.secretName }}
  subPath: {{ $v.subPath }}
{{- end }}
{{- end }}
{{- if and .Values.configMap.enabled (not (eq .Values.configMap.mountPath "")) }}
- mountPath: {{ .Values.configMap.mountPath }}
  name: {{ .Release.Name }}-config
{{- end }}
{{- if .Values.storage.enabled }}
- mountPath: {{ .Values.storage.mountPath }}
  name: {{ .Release.Name }}-data
{{- end }}
{{- end }}

{{/*
Generate volumes
*/}}
{{- define "basic-deployment.volumes" -}}
volumes:
{{- if and .Values.volumesMount.enabled }}
- name: {{ .Release.Name }}-apps-config
  configMap:
    name: {{ .Release.Name }}-apps-config   
{{- end }}   
{{- if and .Values.secret.enabled (not (eq .Values.secret.mountPath "")) }}
- name: {{ .Release.Name }}-secret
  secret:
    secretRef: {{ .Release.Name }}-secret
{{- end }}
{{- range $i, $v := .Values.existingSecrets }}
{{- if and ( default "" $v.mountPath ) ( default "" $v.secretName ) }}
- name: {{ $v.secretName }}
  secret:
    secretRef: {{ $v.secretName }}
{{- end }}
{{- end }}
{{- if and .Values.configMap.enabled (not (eq .Values.configMap.mountPath "")) }}
- name: {{ .Release.Name }}-config
  configMap:
    name: {{ .Release.Name }}-config
{{- end }}
{{- if .Values.storage.enabled }}
- name: {{ .Release.Name }}-data
  persistentVolumeClaim:
    claimName: {{ .Release.Name }}-data
{{- end }}
{{- end }}
