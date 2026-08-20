FROM codercom/enterprise-base:ubuntu

# Run everything as root
USER root

# Install Node.js (LTS)
RUN curl -sL https://deb.nodesource.com/setup_lts.x | bash - && \
    DEBIAN_FRONTEND="noninteractive" apt-get update -y && \
    apt-get install -y nodejs

# Install Yarn. apt-key was removed from modern Ubuntu releases, so trust
# the Yarn repository via a signed-by keyring instead.
RUN curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | gpg --dearmor -o /usr/share/keyrings/yarnkey.gpg && \
    echo "deb [signed-by=/usr/share/keyrings/yarnkey.gpg] https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list && \
    DEBIAN_FRONTEND="noninteractive" apt-get update && apt-get install -y yarn

# Set back to coder user
USER coder
