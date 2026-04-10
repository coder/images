FROM codercom/enterprise-base:ubuntu

# Run everything as root
USER root

# Install JDK (OpenJDK 8)
RUN DEBIAN_FRONTEND="noninteractive" apt-get update -y && \
    apt-get install -y openjdk-11-jdk
ENV JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64
ENV PATH=$PATH:$JAVA_HOME/bin

# Install Maven
ARG MAVEN_VERSION=3.9.14
ARG MAVEN_SHA512=d50af8ab5e6005b46a07f0ce9d3719e67cfdf898da988a84871304cd59fb1af0fef2f99dea709e6e66f21f732f905979b5c2dce6b6860406f60a70e84d9cf0b8

ENV MAVEN_HOME=/usr/share/maven
ENV MAVEN_CONFIG="/home/coder/.m2"

RUN mkdir -p $MAVEN_HOME $MAVEN_HOME/ref \
  && echo "Downloading maven" \
  && curl -fsSL -o /tmp/apache-maven.tar.gz https://archive.apache.org/dist/maven/maven-3/${MAVEN_VERSION}/binaries/apache-maven-${MAVEN_VERSION}-bin.tar.gz \
  && echo "Checking downloaded file hash" \
  && echo "${MAVEN_SHA512}  /tmp/apache-maven.tar.gz" | sha512sum -c - \
  && echo "Unzipping maven" \
  && tar -xzf /tmp/apache-maven.tar.gz -C $MAVEN_HOME --strip-components=1 \
  && echo "Cleaning and setting links" \
  && rm -f /tmp/apache-maven.tar.gz \
  && ln -s $MAVEN_HOME/bin/mvn /usr/bin/mvn

# Install Gradle
ENV GRADLE_VERSION=8.14.2
ARG GRADLE_SHA512=5df80d555e5338c5e67fa3ad11ea8ec534416d3e1414675bdd33a8a8f342ca2cef1ffd882b2f283f56041f6d426adcc5d7d4384e6fbe3eb8edac2c967e9b0ffd

ENV GRADLE_HOME=/usr/bin/gradle

RUN mkdir -p /usr/share/gradle /usr/share/gradle/ref \
  && echo "Downloading gradle" \
  && curl -fsSL -o /tmp/gradle.zip https://services.gradle.org/distributions/gradle-${GRADLE_VERSION}-bin.zip \
  && echo "Checking downloaded file hash" \
  && echo "${GRADLE_SHA512}  /tmp/gradle.zip" | sha512sum -c - \
  && echo "Unziping gradle" \
  && unzip -d /usr/share/gradle /tmp/gradle.zip \
  && echo "Cleaning and setting links" \
  && rm -f /tmp/gradle.zip \
  && ln -s /usr/share/gradle/gradle-${GRADLE_VERSION} /usr/bin/gradle

ENV PATH=$PATH:$GRADLE_HOME/bin

# Set back to coder user
USER coder
