# Coder Example Images

This repository contains example images for use with [Coder](https://coder.com/docs/v2/latest).

- `example-base`: Contains an example image that can be used as a base for
  other images.
- `example-minimal`: Contains a minimal image that contains only the required
  utilities for a Coder workspace to bootstrap successfully.
- `example-golang`: Contains Go development tools.
- `example-java`: Contains Java development tools.
- `example-node`: Contains Node.js development tools.
- `example-desktop`: Contains a desktop environment accessible via web browser.

## Images on Docker Hub

Each of these images is published to Docker Hub under the
`codercom/example-[name]` repository. For example, `base` is available at
https://hub.docker.com/r/codercom/example-base. The tag is taken from the
filename of the Dockerfile. For example, `base/ubuntu.Dockerfile` is
under the `ubuntu` tag.

> For backward compatibility, these images are also available with the `enterprise-` prefix
> (e.g., `codercom/enterprise-base`), but the `example-` prefix is recommended for new deployments.

## Images on GHCR

Images are also published to the GitHub Container Registry (GHCR) under a
distro-based naming convention:

```
ghcr.io/coder/<distro>:<image>
```

For example:

| Image   | GHCR Reference                 |
| ------- | ------------------------------ |
| base    | `ghcr.io/coder/ubuntu:base`    |
| minimal | `ghcr.io/coder/ubuntu:minimal` |
| golang  | `ghcr.io/coder/ubuntu:golang`  |
| java    | `ghcr.io/coder/ubuntu:java`    |
| node    | `ghcr.io/coder/ubuntu:node`    |
| desktop | `ghcr.io/coder/ubuntu:desktop` |

Date-tagged variants are also available (e.g., `ghcr.io/coder/ubuntu:base-20250410`).

## Contributing

See our [contributing guide](.github/CONTRIBUTING.md).

## Changelog

Reference our [changelog](./changelog.md) for updates made to images.
