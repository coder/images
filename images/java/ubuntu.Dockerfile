FROM codercom/enterprise-base:ubuntu

ARG DEBIAN_FRONTEND="noninteractive"
ARG SDKMAN_SHA512="ade94c3b8454bac9411139a46adbd68a16f05766b9bc6fa7061535bbce353c93578393e46cc0d90c630691774d1057b234134fe7af105e1e649f4e8811794de4"

ENV SDKMAN_DIR="/home/coder/.sdkman" \
    SDKMAN_CLI_AUTO_CONFIRM=true \
    JAVA_VERSION="21.0.8-tem" \
    GRADLE_VERSION="8.14.3" \
    MAVEN_VERSION="3.9.11" \
    MAVEN_CONFIG="/home/coder/.m2"

USER root

RUN apt-get update -qq && \
  apt-get install -qq -y \
    --no-install-recommends \
    --no-install-suggests \
    zip && \
  rm -rf /var/lib/apt/lists/*

USER coder

RUN curl -fsSL https://get.sdkman.io -o /tmp/install_sdkman.sh && \
    echo "${SDKMAN_SHA512} /tmp/install_sdkman.sh" | sha512sum -c - && \
    bash /tmp/install_sdkman.sh && \
    rm /tmp/install_sdkman.sh && \
    bash -c "source ${SDKMAN_DIR}/bin/sdkman-init.sh && \
      sdk install java ${JAVA_VERSION} && \
      sdk default java ${JAVA_VERSION} && \
      sdk install gradle ${GRADLE_VERSION} && \
      sdk default gradle ${GRADLE_VERSION} && \
      sdk install maven ${MAVEN_VERSION} && \
      sdk default maven ${MAVEN_VERSION} && \
      sdk flush archives && \
      sdk flush temp && \
      sdk current"
