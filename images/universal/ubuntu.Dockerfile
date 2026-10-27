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

# Rebuild PHP from source to patch CVE-2026-109618 and CVE-2026-109619
# (PHP2Shell). The upstream universal image still pins PHP 8.5.0 and 8.4.15.
# This reuses the upstream PHP feature script (pinned to a commit) so the
# layout, configure flags, Xdebug, and the `current` symlink match the base
# image. Composer lives in /usr/local/bin and is left as is. Remove this step
# once the base image ships PHP 8.5.12 / 8.4.27 or newer.
ARG PHP_VERSION=8.5.12
ARG PHP_ADDITIONAL_VERSIONS=8.4.27
ARG PHP_FEATURE_COMMIT=94181c0188ce13b8c145ab114e887715d45bd982
RUN cp /etc/profile.d/00-restore-env.sh /tmp/00-restore-env.sh && \
    rm -rf /usr/local/php/* && \
    curl -fsSL -o /tmp/php-install.sh \
        "https://raw.githubusercontent.com/devcontainers/features/${PHP_FEATURE_COMMIT}/src/php/install.sh" && \
    VERSION="${PHP_VERSION}" \
    ADDITIONALVERSIONS="${PHP_ADDITIONAL_VERSIONS}" \
    INSTALLCOMPOSER=false \
    USERNAME=codespace \
        bash /tmp/php-install.sh && \
    mv /tmp/00-restore-env.sh /etc/profile.d/00-restore-env.sh && \
    rm -rf /tmp/php-install.sh /var/lib/apt/lists/*

# Disable PHP session upload progress tracking for every installed version,
# and fail the build if any version still reports it as enabled.
RUN for php_dir in /usr/local/php/[0-9]*; do \
        echo "session.upload_progress.enabled=0" >"${php_dir}/ini/conf.d/session.ini" && \
        "${php_dir}/bin/php" -r 'exit((int) ini_get("session.upload_progress.enabled"));' || exit 1; \
    done

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
