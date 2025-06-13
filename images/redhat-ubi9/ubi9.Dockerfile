FROM registry.access.redhat.com/ubi9/ubi:latest

USER root

# Install the Docker CE repository
RUN dnf install -y ca-certificates curl && \
    dnf config-manager --add-repo https://download.docker.com/linux/rhel/docker-ce.repo && \
    dnf clean all

# Install baseline packages
RUN dnf update -y && \
    dnf groupinstall -y "Development Tools" && \
    dnf install -y --setopt=install_weak_deps=False \
    bash \
    containerd.io \
    curl \
    docker-ce \
    docker-ce-cli \
    docker-buildx-plugin \
    docker-compose-plugin \
    git \
    htop \
    jq \
    python3 \
    python3-pip \
    sudo \
    systemd \
    unzip \
    vim \
    wget \
    rsync && \
    dnf clean all

# Enable Docker starting with systemd
RUN systemctl enable docker

# Create a symlink for standalone docker-compose usage
RUN ln -s /usr/libexec/docker/cli-plugins/docker-compose /usr/bin/docker-compose

# Set locale
RUN dnf install -y glibc-langpack-en && \
    dnf clean all
ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US.UTF-8
ENV LC_ALL=en_US.UTF-8

# Add a user `coder` so that you're not developing as the `root` user
RUN useradd coder \
    --create-home \
    --shell=/bin/bash \
    --groups=docker \
    --uid=1000 \
    --user-group && \
    echo "coder ALL=(ALL) NOPASSWD:ALL" >>/etc/sudoers.d/nopasswd

USER coder
