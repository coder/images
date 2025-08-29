FROM codercom/enterprise-base:ubuntu

# Run everything as root
USER root

ENV DEBIAN_FRONTEND="noninteractive" \
    JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64 \
    GRADLE_HOME=/usr/bin/gradle \
    MAVEN_HOME=/usr/share/maven \
    MAVEN_CONFIG="/home/coder/.m2"

ARG MAVEN_VERSION=3.9.11
ARG MAVEN_SHA512=bcfe4fe305c962ace56ac7b5fc7a08b87d5abd8b7e89027ab251069faebee516b0ded8961445d6d91ec1985dfe30f8153268843c89aa392733d1a3ec956c9978
ARG GRADLE_VERSION=6.7
ARG GRADLE_SHA512=d495bc65379d2a854d2cca843bd2eeb94f381e5a7dcae89e6ceb6ef4c5835524932313e7f30d7a875d5330add37a5fe23447dc3b55b4d95dffffa870c0b24493

# Install JDK (OpenJDK 8)
RUN apt-get update -qq && \
    apt-get install -y openjdk-11-jdk && \
    rm -rf /var/lib/apt/lists/*

# Install Maven
RUN mkdir -p $MAVEN_HOME $MAVEN_HOME/ref && \
    echo "Downloading Maven" && \
    curl -fsSL -o /tmp/apache-maven.tar.gz https://repo.maven.apache.org/maven2/org/apache/maven/apache-maven/${MAVEN_VERSION}/apache-maven-${MAVEN_VERSION}-bin.tar.gz && \
    echo "Checking downloaded file hash" && \
    echo "${MAVEN_SHA512} /tmp/apache-maven.tar.gz" | sha512sum -c - && \
    echo "Unzipping Maven" && \
    tar -xzf /tmp/apache-maven.tar.gz -C $MAVEN_HOME --strip-components=1 && \
    echo "Cleaning and setting links" && \
    rm -f /tmp/apache-maven.tar.gz && \
    ln -s $MAVEN_HOME/bin/mvn /usr/bin/mvn

# Install Gradle
RUN mkdir -p /usr/share/gradle /usr/share/gradle/ref && \
    echo "Downloading Gradle" && \
    curl -fsSL -o /tmp/gradle.zip https://services.gradle.org/distributions/gradle-${GRADLE_VERSION}-bin.zip && \
    echo "Checking downloaded file hash" && \
    echo "${GRADLE_SHA512} /tmp/gradle.zip" | sha512sum -c - && \
    echo "Unzipping Gradle" && \
    unzip -d /usr/share/gradle /tmp/gradle.zip && \
    echo "Cleaning and setting links" && \
    rm -f /tmp/gradle.zip && \
    ln -s /usr/share/gradle/gradle-${GRADLE_VERSION} /usr/bin/gradle

ENV PATH=$PATH:$JAVA_HOME/bin:$GRADLE_HOME/bin

# Set back to coder user
USER coder
