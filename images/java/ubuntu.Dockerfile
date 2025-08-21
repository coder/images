FROM codercom/enterprise-base:ubuntu

ARG DEBIAN_FRONTEND="noninteractive"
ARG SDKMAN_SHA512="a8fc6a336d31f2e4980cfe39ee9f11a0f2ee70bc721094b7ea63b953fd1675474765a4e273d6575ea207aa59c15f4fe867e963c0c47580f2131edc2ae8d4fd34"

ENV SDKMAN_DIR="/home/coder/.sdkman" \
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

RUN curl -fsSL "https://get.sdkman.io?ci=true" -o /tmp/install_sdkman.sh && \
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
