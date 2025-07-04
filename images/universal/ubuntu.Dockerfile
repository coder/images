FROM mcr.microsoft.com/devcontainers/universal:linux

USER root

COPY first-run-notice.txt /usr/local/etc/vscode-dev-containers/

# Remove Conda to avoid any license issues
RUN rm -R /opt/conda && \
    rm /usr/local/etc/vscode-dev-containers/conda-notice.txt

RUN userdel -r codespace && \
    useradd coder \
    --create-home \
    --shell=/bin/bash \
    --groups=docker \
    --uid=1000 \
    --user-group && \
echo "coder ALL=(ALL) NOPASSWD:ALL" >>/etc/sudoers.d/nopasswd

USER coder
