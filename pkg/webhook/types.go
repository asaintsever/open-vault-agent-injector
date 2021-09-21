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

package webhook

import (
	cfg "asaintsever/open-vault-agent-injector/pkg/config"
	ctx "asaintsever/open-vault-agent-injector/pkg/context"
	"net/http"
)

// VaultInjector : Webhook Server entity
type VaultInjector struct {
	*cfg.OVAIConfig
	Server *http.Server
}

// Supported annotations (modes' annotations will be appended to this array)
var vaultInjectorAnnotationKeys = []string{
	ctx.VaultInjectorAnnotationInjectKey,
	ctx.VaultInjectorAnnotationVaultImageKey,
	ctx.VaultInjectorAnnotationAuthMethodKey,
	ctx.VaultInjectorAnnotationModeKey,
	ctx.VaultInjectorAnnotationRoleKey,
	ctx.VaultInjectorAnnotationSATokenKey,
	ctx.VaultInjectorAnnotationWorkloadKey,
	ctx.VaultInjectorAnnotationStatusKey,
}

// Supported Vault Auth Methods
var vaultInjectorAuthMethods = [...]string{
	ctx.VaultK8sAuthMethod,
	ctx.VaultAppRoleAuthMethod,
}
