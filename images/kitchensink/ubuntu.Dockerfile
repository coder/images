FROM codercom/enterprise-base:ubuntu

# Run everything as root
USER root

SHELL ["/bin/bash", "-c"]
ENV DEBIAN_FRONTEND=noninteractive

################################################################################
# System packages                                                              #
################################################################################

# The base image already provides build-essential, curl, git, jq, sudo,
# wget, python3, pipx, and Docker.
RUN apt-get update && \
    apt-get install --yes --no-install-recommends --no-install-suggests \
    autoconf \
    automake \
    ca-certificates \
    cmake \
    less \
    sqlite3 \
    zsh \
    && rm -rf /var/lib/apt/lists/*

COPY first-run-notice.txt /usr/local/etc/vscode-dev-containers/

# Everything below installs into user-owned prefixes as the coder user.
USER coder
ENV HOME=/home/coder
ENV PATH=$HOME/.local/bin:$PATH

################################################################################
# Homebrew                                                                     #
################################################################################

# Homebrew 5.0 supports Linux ARM64/AArch64 as Tier 1, so bottles exist
# for both platforms this image builds for.
ENV PATH=/home/linuxbrew/.linuxbrew/bin:/home/linuxbrew/.linuxbrew/sbin:$PATH
RUN NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

RUN brew install \
    cargo-binstall \
    clang-format \
    fish \
    fnm \
    go \
    gofumpt \
    golangci-lint \
    gradle \
    just \
    kotlin \
    maven \
    mise \
    ninja \
    node \
    opentofu \
    pkgconf \
    pnpm \
    rebar3 \
    ruby \
    staticcheck \
    typos-cli \
    uv \
    yarn \
    && brew cleanup --prune=all && \
    rm -rf "$(brew --cache)"

# openjdk is keg-only in Homebrew, so expose it explicitly for tools
# that expect java on PATH.
ENV JAVA_HOME=/home/linuxbrew/.linuxbrew/opt/openjdk
ENV PATH=$PATH:$JAVA_HOME/bin

################################################################################
# uv                                                                           #
################################################################################

RUN uv python install --default 3.14

################################################################################
# rustup                                                                       #
################################################################################

ENV PATH=$HOME/.cargo/bin:$PATH
RUN curl --proto '=https' --tlsv1.2 -fsSL https://sh.rustup.rs | sh -s -- -y \
    --no-modify-path

RUN cargo binstall cargo-nextest --secure

################################################################################
# go                                                                           #
################################################################################

ENV GOPATH=$HOME/go
ENV GOBIN=$GOPATH/bin
ENV PATH=$PATH:$GOBIN

################################################################################
# Sanity checks                                                                #
################################################################################

RUN brew --version && \
    mise --version && \
    go version && \
    node -v && npm -v && yarn -v && pnpm -v && fnm --version && \
    uv --version && python3 --version && \
    cargo -V && cargo nextest --version && \
    ruby --version && \
    java -version && gradle --version && mvn --version && \
    just --version && tofu version
