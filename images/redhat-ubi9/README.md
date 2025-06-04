# Red Hat UBI9 Development Image

A comprehensive development workspace image based on Red Hat Universal Base Image 9 (UBI9) for use with Coder.

## Features

### Base Operating System
- **Red Hat UBI9**: Enterprise-grade, security-focused base image
- **Enterprise Ready**: Red Hat supported with regular security updates
- **Compliance**: Meets enterprise security and compliance requirements

### Development Tools

#### Languages & Runtimes
- **Go 1.24.2**: Latest Go version with complete toolchain
- **Node.js 20**: Latest LTS with npm and pnpm
- **Python 3**: System Python with pip
- **Rust**: Latest stable with Cargo

#### Go Development Tools
- `gopls` - Go language server
- `goimports` - Import management
- `moq` - Mock generation
- `swag` - Swagger documentation
- `swagger` - API client generation
- `migrate` - Database migrations
- `goreleaser` - Release automation
- `gotestsum` - Enhanced test output
- `kind` - Kubernetes in Docker
- `helm-docs` - Helm documentation
- `sqlc` - SQL code generation
- `ruleguard` - Custom linting rules
- `shfmt` - Shell script formatting
- `nfpm` - Package building
- `yq` - YAML processing
- `mockgen` - Interface mocking

#### Infrastructure & DevOps
- **Docker CE**: Container development and deployment
- **Terraform**: Infrastructure as Code
- **kubectl**: Kubernetes command-line tool
- **Helm**: Kubernetes package manager

#### Development Utilities
- **Git**: Version control
- **jq**: JSON processing
- **htop**: Process monitoring
- **tmux**: Terminal multiplexer
- **vim/nano**: Text editors
- **fish/zsh/bash**: Multiple shell options
- **pre-commit**: Git hooks framework

#### Rust Tools
- `jj-cli` - Jujutsu version control
- `typos-cli` - Spell checker
- `watchexec-cli` - File watcher

#### Protocol Buffers
- `protoc` - Protocol buffer compiler
- Go protobuf plugins

## Usage

### With Coder Templates

Use this image in your Coder workspace templates:

```hcl
resource "docker_image" "main" {
  name = "codercom/enterprise-redhat-ubi9"
}

resource "docker_container" "workspace" {
  count = data.coder_workspace.me.start_count
  image = docker_image.main.name
  name  = "coder-${data.coder_workspace.me.owner}-${data.coder_workspace.me.name}"
  
  # Add your configuration here
}
```

### Building Locally

```bash
# Build the image
docker build -f ubi9.Dockerfile -t coder-redhat-ubi9 .

# Run interactively
docker run -it --rm coder-redhat-ubi9
```

### Environment Variables

The image sets up the following environment:

- `GOPATH=/home/coder/go`
- `GOROOT=/usr/local/go`
- `PATH` includes Go, Node.js, and all development tools
- `LANG=en_US.UTF-8`
- `LC_ALL=en_US.UTF-8`

### User Configuration

- **User**: `coder` (non-root)
- **Home**: `/home/coder`
- **Shell**: bash (with zsh and fish available)
- **Sudo**: Passwordless sudo access

### Ports

The following ports are exposed for development:

- `3000` - Frontend development servers
- `8080` - Backend services
- `8443` - HTTPS services

## Use Cases

This image is ideal for:

- **Go Development**: Complete Go development environment
- **Full-Stack Development**: Go backend + Node.js frontend
- **Cloud Native Development**: Kubernetes and container development
- **Infrastructure Development**: Terraform and DevOps workflows
- **Enterprise Environments**: Red Hat compliance and support
- **Multi-language Projects**: Go, Node.js, Python, Rust support

## Security & Compliance

- Based on Red Hat UBI9 for enterprise security
- Regular security updates from Red Hat
- Non-root user execution
- Minimal attack surface with curated tool selection
- Compliance with enterprise security policies

## Size Optimization

- Multi-stage build to minimize final image size
- Package cache cleanup
- Optimized layer structure
- Only essential development tools included

## Support

For issues related to:
- **This image**: Open an issue in the [coder/images](https://github.com/coder/images) repository
- **Coder platform**: Visit [coder.com/docs](https://coder.com/docs)
- **Red Hat UBI9**: Check [Red Hat documentation](https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/9)

## License

This image configuration is provided under the same license as the Coder project.
Red Hat UBI9 is freely redistributable under Red Hat's Universal Base Image End User License Agreement.
