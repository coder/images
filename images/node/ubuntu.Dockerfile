FROM codercom/enterprise-base:ubuntu

# Run everything as root
USER root

ARG TARGETARCH
ARG TARGETVARIANT

# Install Node.js with platform-specific version
# armv7: Node.js 22.x (last version with armv7 support)
# others: Latest LTS
# Ref: https://github.com/nodesource/distributions/issues/1881
RUN NODE_VERSION="lts"; \
    if [ "${TARGETARCH}${TARGETVARIANT}" = "armv7" ]; then \
        NODE_VERSION="22"; \
    fi && \
    curl -sL https://deb.nodesource.com/setup_${NODE_VERSION}.x | bash - && \
    DEBIAN_FRONTEND="noninteractive" apt-get update -y && \
    apt-get install -y nodejs

# Install Yarn
RUN curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add -
RUN echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list
RUN DEBIAN_FRONTEND="noninteractive" apt-get update && apt-get install -y yarn

# Set back to coder user
USER coder
