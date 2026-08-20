# Podman

[![DockerPulls](https://img.shields.io/docker/pulls/codercom/enterprise-podman)](https://hub.docker.com/r/codercom/enterprise-podman)

## Description

Wraps [enterprise-base](../base/README.md) with rootless
[Podman](https://podman.io), so workspaces can build and run containers
without a privileged container runtime or custom RuntimeClass. `docker` is
aliased to `podman`.

This image was previously published as `ghcr.io/coder/podman` from the
now-archived
[community-templates](https://github.com/coder/community-templates/tree/main/kubernetes-podman)
repository.

## How To Use

Visit
[Docker in Workspaces: Rootless Podman](https://coder.com/docs/admin/templates/extending-templates/docker-in-workspaces#rootless-podman)
for the template changes this image pairs with: an AppArmor `unconfined`
profile for the workspace container and a FUSE device exposed via
smarter-device-manager.

Rootless container storage lives under `~/.local/share/containers/storage`,
so it lands on the workspace home volume with no extra mounts required.

Nodes must have Linux user namespaces enabled
(`sysctl user.max_user_namespaces` greater than 0). Notably,
[Bottlerocket](https://github.com/bottlerocket-os/bottlerocket) disables them
by default, and EKS Auto Mode nodes cannot enable them at all.
