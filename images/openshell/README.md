# OpenShell workspace

## Description

Wraps [example-base](../base/README.md) with everything a workspace needs when it
runs inside an [NVIDIA OpenShell](https://docs.nvidia.com/openshell/latest/about/overview)
sandbox that blocks all network access by default: the Coder agent, code-server, and
Claude Code are baked in, so nothing has to be downloaded at start.

It is the workspace image for the
[OpenShell (Kubernetes)](https://registry.coder.com/templates/coder-labs/kubernetes-openshell)
template in the Coder Registry, and the Coder workshops use it for the
"Configure a firewall for autonomous agents" challenge.

## How To Use

Set `workspace_image` in the template's variables file to this image. Match
`CODER_VERSION` to your Coder server. Build args:

| Arg                   | Default   | What it does                                    |
| --------------------- | --------- | ----------------------------------------------- |
| `CODER_VERSION`       | `2.38.5`  | The Coder agent version baked into the image.   |
| `CODER_BINARY_URL`    |           | Download the agent from a URL instead.          |
| `INSTALL_CODE_SERVER` | `true`    | Install code-server under `/opt/code-server`.   |
| `CODE_SERVER_VERSION` | `4.105.1` | The code-server version.                        |
| `INSTALL_CLAUDE_CODE` | `true`    | Install Claude Code under `/opt/claude`.        |

The matching launcher image, which holds only the `openshell` CLI, is Alpine based
and published separately as `ghcr.io/coder/openshell-launcher`.
