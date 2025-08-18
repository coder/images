FROM codercom/enterprise-base:ubuntu

ENV DEBIAN_FRONTEND="noninteractive"
ENV JAVA_VERSION="21.0.8-tem"
ENV GRADLE_VERSION="8.14.3"
ENV MAVEN_VERSION="3.9.11"
ENV MAVEN_CONFIG="/home/coder/.m2"

RUN sudo apt-get update && \
  sudo apt-get install --yes --no-install-recommends --no-install-suggests zip && \
  curl -fsSL "https://get.sdkman.io" | bash && \
  source "/home/coder/.sdkman/bin/sdkman-init.sh" && \
  sdk version && \
  sdk install java $JAVA_VERSION && \
  sdk default java $JAVA_VERSION && \
  sdk install gradle $GRADLE_VERSION && \
  sdk default gradle $GRADLE_VERSION && \
  sdk install maven $MAVEN_VERSION && \
  sdk default maven $MAVEN_VERSION && \
  sdk flush && \
  sdk current java && \
  sdk current gradle && \
  sdk current maven
