ARG UBUNTU_VERSION=resolute
FROM codercom/example-base:ubuntu-${UBUNTU_VERSION}

ARG TARGETARCH=amd64
ARG CODER_VERSION=2.38.5
ARG CODER_BINARY_URL=
ARG INSTALL_CODE_SERVER=true
ARG CODE_SERVER_VERSION=4.105.1
ARG INSTALL_CLAUDE_CODE=true

USER root

# The Coder agent.
RUN set -eu; \
	if [ -n "${CODER_BINARY_URL}" ]; then \
		curl -fsSL --retry 5 -o /usr/local/bin/coder "${CODER_BINARY_URL}"; \
	elif [ -n "${CODER_VERSION}" ]; then \
		v="${CODER_VERSION#v}"; \
		curl -fsSL --retry 5 "https://github.com/coder/coder/releases/download/v${v}/coder_${v}_linux_${TARGETARCH}.tar.gz" \
			| tar -xz -C /usr/local/bin ./coder; \
	else \
		echo "Set CODER_VERSION or CODER_BINARY_URL" >&2; exit 1; \
	fi; \
	chmod 755 /usr/local/bin/coder; \
	/usr/local/bin/coder version

# code-server, outside /home so a home volume does not hide it. The
# code-server module uses it with offline = true.
RUN set -eu; \
	if [ "${INSTALL_CODE_SERVER}" = true ]; then \
		curl -fsSL https://code-server.dev/install.sh \
			| sh -s -- --method=standalone --prefix=/opt/code-server --version "${CODE_SERVER_VERSION}"; \
	fi

# Claude Code, outside /home for the same reason. The template runs
# /opt/claude/bin/claude.
RUN set -eu; \
	if [ "${INSTALL_CLAUDE_CODE}" = true ]; then \
		export HOME=/opt/claude; \
		mkdir -p /opt/claude/bin; \
		curl -fsSL https://claude.ai/install.sh | bash; \
		ln -sf "$(readlink -f /opt/claude/.local/bin/claude)" /opt/claude/bin/claude; \
		chmod -R a+rX /opt/claude; \
		/opt/claude/bin/claude --version; \
	fi

USER coder
WORKDIR /home/coder
