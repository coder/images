FROM codercom/enterprise-base:ubuntu

# Run everything as root
USER root

# Install Podman and rootless dependencies from Ubuntu's own repositories.
# uidmap provides newuidmap/newgidmap, which rootless Podman requires.
RUN apt-get update && \
  DEBIAN_FRONTEND="noninteractive" apt-get install -y --no-install-recommends \
    podman \
    crun \
    fuse-overlayfs \
    slirp4netns \
    uidmap && \
  rm -rf /var/lib/apt/lists/*

# Allow the unprivileged coder user to map subordinate UID/GID ranges for
# rootless containers.
RUN setcap cap_setuid+ep /usr/bin/newuidmap && \
  setcap cap_setgid+ep /usr/bin/newgidmap && \
  chmod 0755 /usr/bin/newuidmap /usr/bin/newgidmap && \
  echo "coder:100000:65536" >/etc/subuid && \
  echo "coder:100000:65536" >/etc/subgid

COPY containers.conf /etc/containers/containers.conf
COPY storage.conf /etc/containers/storage.conf
RUN chmod 644 /etc/containers/containers.conf /etc/containers/storage.conf

# Read-only shared image stores referenced by storage.conf.
RUN mkdir -p /var/lib/shared/overlay-images \
    /var/lib/shared/overlay-layers \
    /var/lib/shared/vfs-images \
    /var/lib/shared/vfs-layers && \
  touch /var/lib/shared/overlay-images/images.lock \
    /var/lib/shared/overlay-layers/layers.lock \
    /var/lib/shared/vfs-images/images.lock \
    /var/lib/shared/vfs-layers/layers.lock

# Alias "docker" to "podman"
RUN [ -e /usr/bin/docker ] || ln -s /usr/bin/podman /usr/bin/docker

# Set back to coder user
USER coder
