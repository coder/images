FROM codercom/enterprise-base:ubuntu

# Run everything as root
USER root

SHELL ["/bin/bash", "-c"]
ENV DEBIAN_FRONTEND=noninteractive

# TARGETARCH is set by buildx/depot to amd64 or arm64 depending on the
# platform being built. It drives the arch-specific installs below.
ARG TARGETARCH

# Install common CLI tooling and language runtimes that are multi-arch
# in the Ubuntu archive: Java, .NET, Ruby, PHP (with Composer), and
# supporting build/network utilities.
RUN apt-get update && \
    apt-get install --yes --no-install-recommends --no-install-suggests \
    composer \
    dnsutils \
    dotnet-sdk-8.0 \
    gnupg \
    less \
    libssl-dev \
    make \
    moreutils \
    net-tools \
    openjdk-21-jdk \
    openssh-client \
    php-cli \
    pkg-config \
    python3-venv \
    ruby-full \
    screen \
    tmux \
    tree \
    zip \
    zsh \
    && rm -rf /var/lib/apt/lists/*

ENV JAVA_HOME=/usr/lib/jvm/java-21-openjdk-${TARGETARCH}
ENV PATH=$PATH:$JAVA_HOME/bin

# Install the GitHub CLI from its official apt repository (multi-arch)
RUN curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg -o /usr/share/keyrings/githubcli-archive-keyring.gpg && \
    chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg && \
    echo "deb [arch=${TARGETARCH} signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" >/etc/apt/sources.list.d/github-cli.list && \
    apt-get update && \
    apt-get install --yes --no-install-recommends --no-install-suggests gh && \
    rm -rf /var/lib/apt/lists/*

# Install Go from the official multi-arch release tarballs
ARG GO_VERSION=1.26.5
RUN curl -fsSL "https://go.dev/dl/go${GO_VERSION}.linux-${TARGETARCH}.tar.gz" | tar -C /usr/local -xz

ENV GOROOT=/usr/local/go
ENV GOPATH=/home/coder/go
ENV GOBIN=$GOPATH/bin
ENV PATH=$PATH:$GOROOT/bin:$GOBIN

# Install Node.js (LTS) via NodeSource (multi-arch), then enable
# Corepack so yarn and pnpm are available without extra repositories.
RUN curl -fsSL https://deb.nodesource.com/setup_lts.x | bash - && \
    apt-get install --yes --no-install-recommends --no-install-suggests nodejs && \
    rm -rf /var/lib/apt/lists/* && \
    corepack enable

# Install a Playwright-managed browser for AI browser testing into a
# shared, world-readable location. Google Chrome only ships linux/amd64
# packages, so arm64 uses Playwright's Chromium build instead.
ENV PLAYWRIGHT_BROWSERS_PATH=/usr/local/ms-playwright
RUN if [ "$TARGETARCH" = "amd64" ]; then \
      yes | npx playwright install chrome; \
    else \
      npx playwright install --with-deps chromium; \
    fi && \
    npm cache clean --force && \
    rm -rf /var/lib/apt/lists/* && \
    { [ ! -d "$PLAYWRIGHT_BROWSERS_PATH" ] || chmod -R a+rX "$PLAYWRIGHT_BROWSERS_PATH"; }

COPY first-run-notice.txt /usr/local/etc/vscode-dev-containers/

# Set back to coder user
USER coder

# Install Rust for the coder user via rustup (multi-arch)
RUN curl -fsSL https://sh.rustup.rs | sh -s -- -y --no-modify-path
ENV PATH=$PATH:/home/coder/.cargo/bin
