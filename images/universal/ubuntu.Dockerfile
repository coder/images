# UBUNTU_VERSION is pinned to noble via UBUNTU_VERSION_OVERRIDES in
# scripts/images.sh because Microsoft's devcontainers/universal image does
# not yet publish a resolute (26.04) tag. See coder/images#335.
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
    sed -i \
        -e 's#/home/codespace#/home/coder#g' \
        -e 's#^export PATH=#export PATH=${PATH:+$PATH:}#' \
        /etc/profile.d/00-restore-env.sh && \
    sed -i \
        -e 's#codespace#coder#g' \
        -e 's#/home/codespace#/home/coder#g' \
        /etc/sudoers.d/codespace && \
    mv /etc/sudoers.d/codespace /etc/sudoers.d/coder && \
    echo "coder ALL=(ALL) NOPASSWD:ALL" >/etc/sudoers.d/nopasswd && \
    chmod 0440 /etc/sudoers.d/coder /etc/sudoers.d/nopasswd

USER coder
