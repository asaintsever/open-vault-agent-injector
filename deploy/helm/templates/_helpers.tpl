{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
Truncate at 63 chars characters due to limitations of the DNS system.
*/}}
{{- define "open-vault-agent-injector.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "open-vault-agent-injector.fullname" -}}
{{- $name := (include "open-vault-agent-injector.name" .) -}}
{{- printf "%s-%s" .Release.Name $name | trunc 40 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default chart name including the version number
*/}}
{{- define "open-vault-agent-injector.chart" -}}
{{- $name := (include "open-vault-agent-injector.name" .) -}}
{{- printf "%s-%s" $name .Chart.Version | replace "+" "_" -}}
{{- end -}}

{{/*
Define mutating webhook failure policy (https://kubernetes.io/docs/reference/access-authn-authz/extensible-admission-controllers/#failure-policy)
Force 'Ignore' if only one replica (because 'Fail' will prevent any pod to start if the only one Open Vault Agent Injector pod is down...)
*/}}
{{- define "open-vault-agent-injector.failurePolicy" -}}
{{- if eq .replicaCount 1.0 -}}
Ignore
{{else}}
{{- .mutatingwebhook.failurePolicy -}}
{{- end -}}
{{- end -}}

{{/*
Define mutating webhook namespace selector
*/}}
{{- define "open-vault-agent-injector.namespaceSelector" -}}
{{- if and (eq .Values.mutatingwebhook.namespaceSelector.boolean true) (eq .Values.mutatingwebhook.namespaceSelector.namespaced false) -}}
namespaceSelector:
  matchLabels:
    vault-injection: enabled
{{- end -}}
{{- if and (eq .Values.mutatingwebhook.namespaceSelector.namespaced true) (eq .Values.mutatingwebhook.namespaceSelector.boolean false) -}}
namespaceSelector:
  matchLabels:
    vault-injection: {{ .Release.Namespace }}
{{- end -}}
{{- if and (eq .Values.mutatingwebhook.namespaceSelector.namespaced true) (eq .Values.mutatingwebhook.namespaceSelector.boolean true) -}}
{{ fail "Cannot enable both mutatingwebhook.namespaceSelector.namespaced and mutatingwebhook.namespaceSelector.boolean values" }}
{{- end -}}
{{- end -}}

{{/*
Define labels which are used throughout the chart files
*/}}
{{- define "open-vault-agent-injector.labels" -}}
com.ovai.application: {{ .Values.image.applicationNameLabel }}
com.ovai.service: {{ .Values.image.serviceNameLabel }}
chart: {{ include "open-vault-agent-injector.chart" . }}
helm.sh/chart: {{ include "open-vault-agent-injector.chart" . }}
release: {{ .Release.Name }}
heritage: {{ .Release.Service }}
{{- end -}}

{{/*
Define the docker image (image.path:image.tag).
*/}}
{{- define "open-vault-agent-injector.image" -}}
{{- printf "%s%s:%s" (default "" .imageRegistry) .image.path (default "latest" .image.tag) -}}
{{- end -}}

{{/*
Define the docker image for Job Babysitter sidecar container (image.path:image.tag).
*/}}
{{- define "open-vault-agent-injector.injectconfig.jobbabysitter.image" -}}
{{- printf "%s%s:%s" (default "" .imageRegistry) .injectconfig.jobbabysitter.image.path (default "latest" .injectconfig.jobbabysitter.image.tag) -}}
{{- end -}}

{{/*
Define the docker image for Vault Agent container (image.path:image.tag).
*/}}
{{- define "open-vault-agent-injector.injectconfig.vault.image" -}}
{{- printf "%s%s:%s" (default "" .imageRegistry) .injectconfig.vault.image.path (default "latest" .injectconfig.vault.image.tag) -}}
{{- end -}}

{{/*
Returns the service name which is by default fixed (not depending on release).
It can be prefixed by the release if the service.prefixWithHelmRelease is true
*/}}
{{- define "open-vault-agent-injector.service.name" -}}
{{- if eq .Values.service.prefixWithHelmRelease true -}}
    {{- $name := .Values.service.name | trunc 63 | trimSuffix "-" -}}
    {{- printf "%s-%s" .Release.Name $name -}}
{{else}}
    {{- .Values.service.name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}

{{/*
Add Vault flag to skip verification of TLS certificates
*/}}
{{- define "open-vault-agent-injector.vault.cert.skip.verify" -}}
{{- if eq .vault.ssl.verify false -}}
-tls-skip-verify
{{- end -}}
{{- end -}}

{{/*
Return the appropriate apiVersion for MutatingWebhookConfiguration
*/}}
{{- define "mutatingwebhookconfiguration.apiversion" -}}
{{- if semverCompare ">=1.16" .Capabilities.KubeVersion.Version -}}
"admissionregistration.k8s.io/v1"
{{- else -}}
"admissionregistration.k8s.io/v1beta1"
{{- end -}}
{{- end -}}
