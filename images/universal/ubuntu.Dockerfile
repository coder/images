ARG UBUNTU_VERSION=noble
FROM mcr.microsoft.com/devcontainers/universal:${UBUNTU_VERSION}

USER root

COPY first-run-notice.txt /usr/local/etc/vscode-dev-containers/

# Remove Conda to avoid any license issues
RUN rm -R /opt/conda && \
    rm /usr/local/etc/vscode-dev-containers/conda-notice.txt

# Install Chrome for AI Browser Testing
RUN yes | npx playwright install chrome

# Rename the upstream `codespace` user to `coder` so we preserve the
# existing home directory and shell environment provided by the base image.
RUN usermod -l coder codespace && \
    groupmod -n coder codespace && \
    usermod -d /home/coder -m coder && \
    usermod -aG docker,sudo coder && \
    echo "coder ALL=(ALL) NOPASSWD:ALL" >>/etc/sudoers.d/nopasswd

USER coder
