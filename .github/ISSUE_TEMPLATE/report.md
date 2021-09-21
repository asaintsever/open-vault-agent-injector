---
name: Report
about: Report Open Vault Agent Injector issue
title: ''
labels: ''
assignees: asaintsever

---

**Describe the issue**
A clear and concise description of what the issue is.

**To Reproduce**

Steps to reproduce the behavior

**Expected behavior**

A clear and concise description of what you expected to happen.

**Screenshots**

If applicable, add screenshots to help explain your problem.

**Environment (please complete the following information):**

 - Workstation OS: [e.g. Ubuntu 18.04]
 - Kubernetes
    - cluster: [e.g. AKS, EKS, Minikube, Kind, k3s]
    - version of Kubernetes
 - Vault Server
    - version
    - chart version (if Kubernetes install)
    - in-cluster or external instance
 - Open Vault Agent Injector
    - chart version: [e.g. 3.1.1]

**Additional context**

Add any other context about the problem here.

**Content of deployed Kubernetes manifest**

If possible, full content of your manifest with Open Vault Agent Injector annotations and info about your workload such as image path, command, env, volumes & mounts ...

**Log of Vault Server**

Warnings and errors related to the issue

**Logs of Open Vault Agent Injector pod(s)**

Errors reported by Open Vault Agent Injector while trying to inject Vault Agent into your workload

**Logs of your workload**

In particular, logs from the Vault Agent sidecar container injected into your pod
