
# CloudFormation tools (cfn-tools)

Installs cfn-lint, cfn-flip, rain and yq for working with CloudFormation templates

## Example Usage

```json
"features": {
    "ghcr.io/paul-e-allen/feature-starter/cfn-tools:1": {}
}
```

## Options

| Options Id | Description | Type | Default Value |
|-----|-----|-----|-----|
| rain-version | rain version to install (without the leading 'v') | string | 1.24.4 |
| yq-version | yq version to install (without the leading 'v') | string | 4.54.1 |
| update-specs | When to run 'cfn-lint --update-specs': in the background after the container is created, or never | string | background |



---

_Note: This file was auto-generated from the [devcontainer-feature.json](https://github.com/paul-e-allen/feature-starter/blob/main/src/cfn-tools/devcontainer-feature.json).  Add additional notes to a `NOTES.md`._
