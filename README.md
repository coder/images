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

### Available Tags

Each image is published with the following tag variants:

| Tag                       | Example                                       | Description                                        |
| ------------------------- | --------------------------------------------- | -------------------------------------------------- |
| `ubuntu`                  | `codercom/example-base:ubuntu`                | Latest Ubuntu version (rolling)                    |
| `ubuntu-{version}`        | `codercom/example-base:ubuntu-noble`          | Pinned to a specific Ubuntu release                |
| `ubuntu-{date}`           | `codercom/example-base:ubuntu-20250101`       | Snapshot from a specific build date                |
| `ubuntu-{version}-{date}` | `codercom/example-base:ubuntu-noble-20250101` | Version-pinned snapshot from a specific build date |
| `latest`                  | `codercom/example-base:latest`                | Alias for the latest build                         |

> For backward compatibility, these images are also available with the `enterprise-` prefix
> (e.g., `codercom/enterprise-base`), but the `example-` prefix is recommended for new deployments.

## Contributing

See our [contributing guide](.github/CONTRIBUTING.md).

## Changelog

Reference our [changelog](./changelog.md) for updates made to images.
