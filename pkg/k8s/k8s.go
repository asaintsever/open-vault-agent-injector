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
	"encoding/base64"
	"errors"
	"fmt"
	"io/ioutil"
	"os"
	"strings"

	corev1 "k8s.io/api/core/v1"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"k8s.io/apimachinery/pkg/types"
	"k8s.io/client-go/kubernetes"
	"k8s.io/client-go/rest"
	"k8s.io/klog"
)

// New : init K8S client
func New(whk *WebhookData) *K8SClient {
	// In-cluster K8S client: must exist obviously
	k8sConfig, err := rest.InClusterConfig()
	if err != nil {
		klog.Errorf("Failed to load in-cluster K8S config: %s", err)
		panic(err)
	}

	k8sClientset, err := kubernetes.NewForConfig(k8sConfig)
	if err != nil {
		klog.Errorf("Error creating K8S client: %s", err)
		panic(err)
	}

	return &K8SClient{k8sClientset, whk}
}

// CreateCertSecret creates a Kubernetes Secret storing webhook CA, certificate and private key
func (k8sctl *K8SClient) CreateCertSecret(ca, cert, key []byte) error {
	secret := &corev1.Secret{
		ObjectMeta: metav1.ObjectMeta{
			Name: k8sctl.WebhookSecretName,
		},
		Data: map[string][]byte{
			k8sctl.WebhookCACertName: ca,
			k8sctl.WebhookCertName:   cert,
			k8sctl.WebhookKeyName:    key,
		},
	}

	// Get current namespace
	ns, ok := os.LookupEnv("POD_NAMESPACE")
	if !ok {
		klog.Errorf("Failed to get current namespace from 'POD_NAMESPACE' env var")
		return errors.New("Failed to get current namespace")
	}

	// Other way to get current namespace:
	//ns, err := ioutil.ReadFile("/var/run/secrets/kubernetes.io/serviceaccount/namespace")

	// If secret already exists: log a warning before deleting it
	if _, err := k8sctl.CoreV1().Secrets(strings.TrimSpace(string(ns))).Get(k8sctl.WebhookSecretName, metav1.GetOptions{}); err == nil {
		klog.Warning("Webhook secret already exists: will be deleted then created again from new generated certificate")
		k8sctl.DeleteCertSecret()
	}

	// Create Secret in same namespace as webhook
	_, err := k8sctl.CoreV1().Secrets(strings.TrimSpace(string(ns))).Create(secret)
	if err != nil {
		klog.Errorf("Failed creating Webhook secret: %s", err)
		return err
	}

	return nil
}

// DeleteCertSecret deletes the Kubernetes Secret used for storing webhook CA, certificate and private key
func (k8sctl *K8SClient) DeleteCertSecret() error {
	// Get current namespace
	ns, ok := os.LookupEnv("POD_NAMESPACE")
	if !ok {
		klog.Errorf("Failed to get current namespace from 'POD_NAMESPACE' env var")
		return errors.New("Failed to get current namespace")
	}

	// Other way to get current namespace:
	//ns, err := ioutil.ReadFile("/var/run/secrets/kubernetes.io/serviceaccount/namespace")

	// Delete Secret
	err := k8sctl.CoreV1().Secrets(strings.TrimSpace(string(ns))).Delete(k8sctl.WebhookSecretName, &metav1.DeleteOptions{})
	if err != nil {
		klog.Errorf("Failed deleting Webhook secret: %s", err)
		return err
	}

	return nil
}

// PatchWebhookConfiguration reads CA certificate then patches MutatingWebhookConfiguration's caBundle
func (k8sctl *K8SClient) PatchWebhookConfiguration(cacertfile string) error {
	caPEM, err := ioutil.ReadFile(cacertfile)
	if err != nil {
		klog.Errorf("Failed to read CA cert file: %s", err)
		return err
	}

	webhookPatch := []byte(fmt.Sprintf(
		`[{
			"op": "add",
			"path": "/webhooks/0/clientConfig/caBundle",
			"value": %q
		}]`, base64.StdEncoding.EncodeToString(caPEM)))

	// Patch MutatingWebhookConfiguration resource with CA (should be base64-encoded PEM-encoded)
	if _, err = k8sctl.AdmissionregistrationV1().MutatingWebhookConfigurations().Get(k8sctl.WebhookCfgName, metav1.GetOptions{}); err == nil {
		// v1 support
		klog.Infof("Patching MutatingWebhookConfiguration v1 resource %v", k8sctl.WebhookCfgName)
		if _, err = k8sctl.AdmissionregistrationV1().MutatingWebhookConfigurations().Patch(k8sctl.WebhookCfgName, types.JSONPatchType, webhookPatch); err != nil {
			klog.Errorf("Error patching MutatingWebhookConfiguration's caBundle: %s", err)
			return err
		}
	} else {
		// v1beta1 support
		klog.Infof("Patching MutatingWebhookConfiguration v1beta1 resource %v", k8sctl.WebhookCfgName)
		if _, err = k8sctl.AdmissionregistrationV1beta1().MutatingWebhookConfigurations().Patch(k8sctl.WebhookCfgName, types.JSONPatchType, webhookPatch); err != nil {
			klog.Errorf("Error patching MutatingWebhookConfiguration's caBundle: %s", err)
			return err
		}
	}

	return nil
}
