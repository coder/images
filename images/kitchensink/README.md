# Example Kitchensink Image

[![Docker Pulls](https://img.shields.io/docker/pulls/codercom/example-kitchensink?label=codercom%2Fexample-kitchensink)](https://hub.docker.com/r/codercom/example-kitchensink)

## Description

A multi-language "kitchen sink" image built on `codercom/enterprise-base:ubuntu`, published for `linux/amd64` and `linux/arm64`. It offers a multi-arch alternative to the `universal` image, whose upstream base ([Microsoft's Universal Dev Container Image](https://github.com/devcontainers/images/tree/main/src/universal)) is only published for amd64.

Toolchains are installed via Homebrew (Tier 1 on Linux ARM64 as of Homebrew 5.0), plus dedicated version managers:

- Homebrew: Go (with `gofumpt`, `golangci-lint`, `staticcheck`), Node.js (with `yarn`, `pnpm`, `fnm`), Ruby, Kotlin, Gradle, Maven, `mise`, `just`, `ninja`, `cmake`, OpenTofu, `fish`, `typos-cli`, `clang-format`, `pkgconf`, `rebar3`
- `uv` with a default Python install
- Rust via `rustup` (with `cargo-binstall` and `cargo-nextest`)
- Docker, Git, and common shell utilities inherited from the base image

All user-facing tooling runs as the `coder` user.
