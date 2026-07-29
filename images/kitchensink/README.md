# Example Kitchensink Image

[![Docker Pulls](https://img.shields.io/docker/pulls/codercom/example-kitchensink?label=codercom%2Fexample-kitchensink)](https://hub.docker.com/r/codercom/example-kitchensink)

## Description

A multi-language "kitchen sink" image built on `codercom/enterprise-base:ubuntu`, published for `linux/amd64` and `linux/arm64`. It offers a multi-arch alternative to the `universal` image, whose upstream base ([Microsoft's Universal Dev Container Image](https://github.com/devcontainers/images/tree/main/src/universal)) is only published for amd64.

Included toolchains and utilities:

- Python 3 (with `pipx` and `venv`, inherited from the base image)
- Node.js LTS (with `yarn` and `pnpm` via Corepack)
- Go
- Java (OpenJDK 21)
- .NET SDK 8.0
- Ruby
- PHP (with Composer)
- Rust (via `rustup`, installed for the `coder` user)
- Docker, Git, GitHub CLI, and common shell utilities
- A Playwright-managed browser for AI browser testing (Google Chrome on amd64, Chromium on arm64, at `/usr/local/ms-playwright`)
