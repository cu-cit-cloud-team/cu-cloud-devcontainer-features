
# Terraform tools (terraform-tools)

Installs tfenv and a default Terraform version managed by tfenv

## Example Usage

```json
"features": {
    "ghcr.io/paul-e-allen/feature-starter/terraform-tools:1": {}
}
```

## Options

| Options Id | Description | Type | Default Value |
|-----|-----|-----|-----|
| tfenv-version | tfenv version to install (without the leading 'v') | string | 3.2.2 |
| terraform-version | Terraform version to install with tfenv and select as the default | string | 1.5.5 |



---

_Note: This file was auto-generated from the [devcontainer-feature.json](https://github.com/paul-e-allen/feature-starter/blob/main/src/terraform-tools/devcontainer-feature.json).  Add additional notes to a `NOTES.md`._
