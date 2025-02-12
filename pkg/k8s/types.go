// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

package k8s

import (
	k8s "k8s.io/client-go/kubernetes"
)

type K8SClient struct {
	*k8s.Clientset // Inner Kubernetes client
	*WebhookData   // Webhook data
}

type WebhookData struct {
	WebhookSecretName string // Name of Kubernetes secret to create
	WebhookCACertName string // Name of secret entry for webhook CA certificate
	WebhookCertName   string // Name of secret entry for webhook certificate
	WebhookKeyName    string // Name of secret entry for webhook private key
	WebhookCfgName    string // Name of MutatingWebhookConfiguration resource
}
