# Red Hat UBI9 based development container for Coder workspaces
# This Dockerfile creates a development environment based on Red Hat Universal Base Image 9

# Multi-stage build for Go tools
FROM registry.access.redhat.com/ubi9/go-toolset:1.21 AS go-builder

USER root

# Install Go manually to get the latest version
ARG GO_VERSION=1.24.2
RUN curl -L "https://go.dev/dl/go${GO_VERSION}.linux-amd64.tar.gz" -o /tmp/go.tar.gz && \
    rm -rf /usr/local/go && \
    tar -C /usr/local -xzf /tmp/go.tar.gz && \
    rm /tmp/go.tar.gz

ENV PATH=/usr/local/go/bin:$PATH
ENV GOPATH=/tmp/go

# Install Go development tools
RUN mkdir -p "$GOPATH" && \
    go install github.com/matryer/moq@v0.2.3 && \
    go install github.com/swaggo/swag/cmd/swag@v1.7.4 && \
    go install github.com/go-swagger/go-swagger/cmd/swagger@v0.28.0 && \
    go install golang.org/x/tools/cmd/goimports@v0.31.0 && \
    go install google.golang.org/protobuf/cmd/protoc-gen-go@v1.30 && \
    go install storj.io/drpc/cmd/protoc-gen-go-drpc@v0.0.34 && \
    go install github.com/golang-migrate/migrate/v4/cmd/migrate@v4.15.1 && \
    go install github.com/goreleaser/goreleaser@v1.6.1 && \
    go install golang.org/x/tools/gopls@v0.18.1 && \
    go install gotest.tools/gotestsum@v1.9.0 && \
    go install github.com/mattn/goveralls@v0.0.11 && \
    go install sigs.k8s.io/kind@v0.10.0 && \
    go install github.com/norwoodj/helm-docs/cmd/helm-docs@v1.5.0 && \
    CGO_ENABLED=1 go install github.com/sqlc-dev/sqlc/cmd/sqlc@v1.27.0 && \
    go install github.com/sethvargo/gcr-cleaner/cmd/gcr-cleaner-cli@v0.5.1 && \
    go install github.com/quasilyte/go-ruleguard/cmd/ruleguard@v0.3.13 && \
    go install mvdan.cc/sh/v3/cmd/shfmt@v3.7.0 && \
    go install github.com/goreleaser/nfpm/v2/cmd/nfpm@v2.35.1 && \
    go install github.com/mikefarah/yq/v4@v4.44.3 && \
    mv /tmp/go/bin/yq /tmp/go/bin/yq4 && \
    go install go.uber.org/mock/mockgen@v0.5.0

# Rust tools stage
FROM registry.access.redhat.com/ubi9/ubi:latest AS rust-builder

RUN dnf install -y gcc openssl-devel pkg-config && \
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y

ENV PATH="/root/.cargo/bin:${PATH}"
ENV CARGO_INSTALL_ROOT=/tmp/cargo

RUN cargo install jj-cli typos-cli watchexec-cli

# Protocol Buffers stage
FROM registry.access.redhat.com/ubi9/ubi-minimal:latest AS proto-builder

RUN microdnf install -y curl unzip && \
    curl -L -o /tmp/protoc.zip https://github.com/protocolbuffers/protobuf/releases/download/v23.4/protoc-23.4-linux-x86_64.zip && \
    cd /tmp && unzip protoc.zip && rm protoc.zip

# Main development image
FROM registry.access.redhat.com/ubi9/ubi:latest

LABEL name="coder-redhat-ubi9" \
      vendor="Red Hat" \
      version="1.0" \
      release="1" \
      summary="Coder workspace image based on Red Hat UBI9" \
      description="A Red Hat UBI9 based workspace image for Coder with Go, Node.js, and development tools"

# Create coder user
RUN useradd -m -s /bin/bash coder && \
    echo 'coder ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/coder && \
    chmod 640 /etc/sudoers.d/coder

# Install EPEL and enable additional repositories
RUN dnf install -y epel-release && \
    dnf config-manager --set-enabled crb

# Install development packages
RUN dnf update -y && \
    dnf groupinstall -y "Development Tools" && \
    dnf install -y \
        bash-completion \
        bind-utils \
        cmake \
        curl \
        file \
        fish \
        git \
        htop \
        jq \
        less \
        make \
        nano \
        openssh-clients \
        procps-ng \
        python3 \
        python3-pip \
        rsync \
        sudo \
        tar \
        tmux \
        tree \
        unzip \
        vim \
        wget \
        which \
        zip \
        zsh && \
    dnf clean all

# Install Node.js 20 from NodeSource
RUN curl -fsSL https://rpm.nodesource.com/setup_20.x | bash - && \
    dnf install -y nodejs

# Install pnpm
RUN npm install -g pnpm

# Install Docker CE
RUN dnf config-manager --add-repo https://download.docker.com/linux/rhel/docker-ce.repo && \
    dnf install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

# Install Terraform
RUN dnf config-manager --add-repo https://rpm.releases.hashicorp.com/RHEL/hashicorp.repo && \
    dnf install -y terraform

# Install kubectl
RUN curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" && \
    install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl && \
    rm kubectl

# Install Helm
RUN curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# Copy Go tools from builder stage
COPY --from=go-builder /tmp/go/bin/* /usr/local/bin/
COPY --from=go-builder /usr/local/go /usr/local/go

# Copy Rust tools from builder stage
COPY --from=rust-builder /tmp/cargo/bin/* /usr/local/bin/

# Copy Protocol Buffers from builder stage
COPY --from=proto-builder /tmp/bin/protoc /usr/local/bin/
COPY --from=proto-builder /tmp/include /usr/local/include

# Set up Go environment
ENV PATH=/usr/local/go/bin:$PATH
ENV GOPATH=/home/coder/go
ENV GOPROXY=https://proxy.golang.org,direct
ENV GOSUMDB=sum.golang.org

# Set up development environment
RUN mkdir -p /home/coder/go/{bin,src,pkg} && \
    chown -R coder:coder /home/coder

# Install additional development tools
RUN pip3 install --user pre-commit

# Set locale
ENV LANG=en_US.UTF-8
ENV LC_ALL=en_US.UTF-8

# Switch to coder user
USER coder
WORKDIR /home/coder

# Set up shell environment
RUN echo 'export PATH="$PATH:/usr/local/go/bin:$GOPATH/bin"' >> ~/.bashrc && \
    echo 'export GOPATH="$HOME/go"' >> ~/.bashrc && \
    echo 'alias ll="ls -la"' >> ~/.bashrc && \
    echo 'alias la="ls -A"' >> ~/.bashrc && \
    echo 'alias l="ls -CF"' >> ~/.bashrc

# Expose common development ports
EXPOSE 3000 8080 8443

CMD ["/bin/bash"]
