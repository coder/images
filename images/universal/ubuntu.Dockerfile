FROM mcr.microsoft.com/devcontainers/base:ubuntu

USER root

COPY first-run-notice.txt /usr/local/etc/vscode-dev-containers/

# Install universal development tools
# Common development tools, programming languages and runtimes, additional tools
RUN apt-get update && export DEBIAN_FRONTEND=noninteractive \
    && apt-get -y install --no-install-recommends \
        build-essential \
        curl \
        wget \
        git \
        vim \
        nano \
        unzip \
        zip \
        python3 \
        python3-pip \
        python3-venv \
        nodejs \
        npm \
        openjdk-11-jdk \
        jq \
        htop \
        tree \
        && apt-get autoremove -y && apt-get clean -y && rm -rf /var/lib/apt/lists/*

# Install Go
RUN wget -O go.tar.gz https://go.dev/dl/go1.21.5.linux-amd64.tar.gz \
    && tar -C /usr/local -xzf go.tar.gz \
    && rm go.tar.gz

# Install Maven
RUN wget -O maven.tar.gz https://downloads.apache.org/maven/maven-3/3.9.10/binaries/apache-maven-3.9.10-bin.tar.gz \
    && tar -C /opt -xzf maven.tar.gz \
    && mv /opt/apache-maven-3.9.10 /opt/maven \
    && rm maven.tar.gz

# Set up environment variables
ENV PATH="/usr/local/go/bin:/opt/maven/bin:${PATH}"
ENV JAVA_HOME="/usr/lib/jvm/java-11-openjdk-amd64"
ENV MAVEN_HOME="/opt/maven"

# Create coder user
RUN useradd coder \
    --create-home \
    --shell=/bin/bash \
    --groups=docker \
    --uid=1000 \
    --user-group && \
echo "coder ALL=(ALL) NOPASSWD:ALL" >>/etc/sudoers.d/nopasswd

USER coder
