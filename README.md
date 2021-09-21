
# Open Vault Agent Injector *(OVAI)*

`Open Vault Agent Injector` allows to dynamically inject HashiCorp Vault Agent as either an init or a sidecar container, along with configuration and volumes, in any matching pod manifest **to seamlessly fetch secrets from Vault**. Pods willing to benefit from this feature just have to add some custom annotations to ask for the injection **at deployment time**.

*This component is based on a fork of [Talend's Vault Sidecar Injector](https://github.com/Talend/vault-sidecar-injector).*

## Announcements

- 2021-09: First Open Vault Agent Injector release!
- 2020-06: [Inject secrets in your pod as environment variables](doc/announcements/Injecting-secrets-in-env.md)
- 2020-03: [Static vs Dynamic secrets](doc/announcements/Static-vs-Dynamic-Secrets.md)
- 2019-12: [Discovering the Vault Proxy feature](doc/announcements/Discovering-Vault-Proxy.md)

## Kubernetes compatibility

`Open Vault Agent Injector` can be deployed on Kubernetes `1.12` and higher. Deployment on earlier versions *may work* but has not been tested.

## Usage

- [How to invoke Open Vault Agent Injector](doc/Usage.md)
- [Examples](doc/Examples.md)

## Installation

- [How to deploy Open Vault Agent Injector](doc/Deploy.md)
- [Configuration](doc/Configuration.md)

## Observability

- [Metrics](doc/Metrics.md)

## List of changes

Look at changes for Open Vault Agent Injector releases in [CHANGELOG](CHANGELOG.md) file.

## Contributing

Feel free to create [issues](https://github.com/asaintsever/open-vault-agent-injector/issues) or submit [pull requests](https://github.com/asaintsever/open-vault-agent-injector/pulls).

## License

This project is licensed under the terms of the Apache 2.0 license.
