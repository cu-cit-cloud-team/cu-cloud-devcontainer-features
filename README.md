# Dev Container Features

## Features in this repository

This repository contains a _collection_ of four Features under [`src/`](src). Each sub-section below shows a sample `devcontainer.json` alongside example usage.

### `aws-cli-base`

Installs the AWS CLI (without the AWS VS Code plugins), optionally the Session Manager plugin, and the `ssmhost` helper script, which connects to an EC2 instance by Name tag or instance ID via SSM.

| Option | Type | Default | Description |
|---|---|---|---|
| `ssm-session-manager` | boolean | `true` | Also install the AWS Systems Manager Session Manager plugin (and `ssmhost`) |

```jsonc
{
    "image": "mcr.microsoft.com/devcontainers/base:ubuntu",
    "features": {
        "ghcr.io/cu-cit-cloud-team/cu-cloud-devcontainer-features/aws-cli-base:1": {
            "ssm-session-manager": true
        }
    }
}
```

```bash
$ ssmhost my-instance-name
```


### `cfn-tools`

Installs `cfn-lint` and `cfn-flip` (in a virtualenv, symlinked into `/usr/local/bin`), plus `rain` and `yq`. Depends on (and installs after) `ghcr.io/devcontainers/features/python:1`.

| Option | Type | Default | Description |
|---|---|---|---|
| `rain-version` | string | `1.24.4` | rain version to install (without the leading `v`) |
| `yq-version` | string | `4.54.1` | yq version to install (without the leading `v`) |
| `update-specs` | string (`background`, `none`) | `background` | Run `cfn-lint --update-specs` in the background after the container is created (`postCreateCommand`), or never |

```jsonc
"features": {
    "ghcr.io/cu-cit-cloud-team/cu-cloud-devcontainer-features/cfn-tools:1": {
        "rain-version": "1.24.4",
        "update-specs": "background"
    }
}
```

### `terraform-tools`

Installs `tfenv` and a default Terraform version managed by `tfenv`. Sets `TF_PLUGIN_CACHE_DIR` to `/opt/terraform/plugin-cache`.

| Option | Type | Default | Description |
|---|---|---|---|
| `tfenv-version` | string | `3.2.2` | tfenv version to install (without the leading `v`) |
| `terraform-version` | string | `1.5.5` | Terraform version to install with tfenv and select as the default |

```jsonc
"features": {
    "ghcr.io/cu-cit-cloud-team/cu-cloud-devcontainer-features/terraform-tools:1": {
        "terraform-version": "1.5.5"
    }
}
```

### `uv`

Installs `uv`/`uvx` so MCP servers requiring it can run in the container. It has no options.

```jsonc
"features": {
    "ghcr.io/cu-cit-cloud-team/cu-cloud-devcontainer-features/uv:1": {}
}
```

## Repo and Feature Structure

Similar to the [`devcontainers/features`](https://github.com/devcontainers/features) repo, this repository has a `src` folder.  Each Feature has its own sub-folder, containing at least a `devcontainer-feature.json` and an entrypoint script `install.sh`. Each Feature also has a matching `test/<feature>/test.sh`.

```
├── src
│   ├── aws-cli-base
│   │   ├── devcontainer-feature.json
│   │   ├── install.sh
│   │   ├── install-ssm-plugin.sh
│   │   └── ssmhost
│   ├── cfn-tools
│   │   ├── devcontainer-feature.json
│   │   └── install.sh
│   ├── terraform-tools
│   │   ├── devcontainer-feature.json
│   │   └── install.sh
│   └── uv
│       ├── devcontainer-feature.json
│       └── install.sh
└── test
    ├── aws-cli-base/test.sh
    ├── cfn-tools/test.sh
    ├── terraform-tools/test.sh
    └── uv/test.sh
```

An [implementing tool](https://containers.dev/supporting#tools) will composite [the documented dev container properties](https://containers.dev/implementors/features/#devcontainer-feature-json-properties) from the feature's `devcontainer-feature.json` file, and execute in the `install.sh` entrypoint script in the container during build time.  Implementing tools are also free to process attributes under the `customizations` property as desired.

### Options

All available options for a Feature should be declared in the `devcontainer-feature.json`.  The syntax for the `options` property can be found in the [devcontainer Feature json properties reference](https://containers.dev/implementors/features/#devcontainer-feature-json-properties).

For example, the `cfn-tools` feature declares an enum option `update-specs` (`background` or `none`).  If no option is provided in a user's `devcontainer.json`, the value is set to `background`.

```jsonc
{
    // ...
    "options": {
        "update-specs": {
            "type": "string",
            "enum": ["background", "none"],
            "default": "background",
            "description": "When to run 'cfn-lint --update-specs': in the background after the container is created, or never"
        }
    }
}
```

Options are exported as Feature-scoped environment variables.  The option name is capitalized and sanitized according to [option resolution](https://containers.dev/implementors/features/#option-resolution) (e.g. `ssm-session-manager` becomes `SSM_SESSION_MANAGER`).

## Distributing Features

### Versioning

Features are individually versioned by the `version` attribute in a Feature's `devcontainer-feature.json`.  Features are versioned according to the semver specification. More details can be found in [the dev container Feature specification](https://containers.dev/implementors/features/#versioning).

### Publishing

> NOTE: The Distribution spec can be [found here](https://containers.dev/implementors/features-distribution/).  
>
> While any registry [implementing the OCI Distribution spec](https://github.com/opencontainers/distribution-spec) can be used, this template will leverage GHCR (GitHub Container Registry) as the backing registry.

Features are meant to be easily sharable units of dev container configuration and installation code.  

This repo contains a **GitHub Action** [workflow](.github/workflows/release.yaml) that will publish each Feature to GHCR. 

*Allow GitHub Actions to create and approve pull requests* should be enabled in the repository's `Settings > Actions > General > Workflow permissions` for auto generation of `src/<feature>/README.md` per Feature (which merges any existing `src/<feature>/NOTES.md`).

By default, each Feature will be prefixed with the `<owner/<repo>` namespace.  For example, the Features in this repository can be referenced in a `devcontainer.json` with:

```
ghcr.io/cu-cit-cloud-team/cu-cloud-devcontainer-features/aws-cli-base:1
ghcr.io/cu-cit-cloud-team/cu-cloud-devcontainer-features/aws-mcps:1
ghcr.io/cu-cit-cloud-team/cu-cloud-devcontainer-features/cfn-tools:1
ghcr.io/cu-cit-cloud-team/cu-cloud-devcontainer-features/terraform-tools:1
```

The provided GitHub Action will also publish an additional "metadata" package with just the namespace, eg: `ghcr.io/cu-cit-cloud-team/cu-cloud-devcontainer-features`.  This contains information useful for tools aiding in Feature discovery.

'`cu-cit-cloud-team/cu-cloud-devcontainer-features`' is known as the feature collection namespace.

### Marking Feature Public

Note that by default, GHCR packages are marked as `private`.  To stay within the free tier, Features need to be marked as `public`.

This can be done by navigating to the Feature's "package settings" page in GHCR, and setting the visibility to 'public`.  The URL may look something like:

```
https://github.com/users/<owner>/packages/container/<repo>%2F<featureName>/settings
```
