FROM codercom/enterprise-base:ubuntu

# Run everything as root
USER root

ENV JAVA_HOME=/usr/lib/jvm/java-21-openjdk-amd64
ENV PATH=$PATH:$JAVA_HOME/bin
ENV DEBIAN_FRONTEND=noninteractive

# Install JDK (OpenJDK 21)
RUN apt-get update -y \
  && apt-get install openjdk-21-jdk -y --no-install-recommends --no-install-suggests

# Install Maven
ARG MAVEN_VERSION=3.9.11
ARG MAVEN_SHA512=bcfe4fe305c962ace56ac7b5fc7a08b87d5abd8b7e89027ab251069faebee516b0ded8961445d6d91ec1985dfe30f8153268843c89aa392733d1a3ec956c9978

ENV MAVEN_HOME=/usr/share/maven
ENV MAVEN_CONFIG="/home/coder/.m2"

RUN mkdir -p $MAVEN_HOME $MAVEN_HOME/ref \
  && echo "Downloading Maven" \
  && curl -fsSL -o /tmp/apache-maven.tar.gz https://dlcdn.apache.org/maven/maven-3/${MAVEN_VERSION}/binaries/apache-maven-${MAVEN_VERSION}-bin.tar.gz \
  && echo "Checking downloaded file hash" \
  && echo "${MAVEN_SHA512} /tmp/apache-maven.tar.gz" | sha512sum -c - \
  && echo "Unzipping Maven" \
  && tar -xzf /tmp/apache-maven.tar.gz -C $MAVEN_HOME --strip-components=1 \
  && echo "Cleaning and setting links" \
  && rm -f /tmp/apache-maven.tar.gz \
  && ln -s $MAVEN_HOME/bin/mvn /usr/bin/mvn

# Install Gradle
ENV GRADLE_VERSION=8.14.3
ARG GRADLE_SHA512=517ed3a20fe9f14f8c7e34778f5d248c61473e2b67e48a6d3341682a4bdcab502723f1d985fbb9e7f360a74a4e15f113d08a515bcc7b56dd5eb426f8e2cf82bf

ENV GRADLE_HOME=/usr/bin/gradle

RUN mkdir -p /usr/share/gradle /usr/share/gradle/ref \
  && echo "Downloading Gradle" \
  && curl -fsSL -o /tmp/gradle.zip https://services.gradle.org/distributions/gradle-${GRADLE_VERSION}-bin.zip \
  && echo "Checking downloaded file hash" \
  && echo "${GRADLE_SHA512} /tmp/gradle.zip" | sha512sum -c - \
  && echo "Unzipping Gradle" \
  && unzip -q -d /usr/share/gradle /tmp/gradle.zip \
  && echo "Cleaning and setting links" \
  && rm -f /tmp/gradle.zip \
  && ln -s /usr/share/gradle/gradle-${GRADLE_VERSION} /usr/bin/gradle

ENV PATH=$PATH:$GRADLE_HOME/bin

# Set back to coder user
USER coder
