# Red Hat UBI9 Base Image

[![Docker Pulls](https://img.shields.io/docker/pulls/codercom/enterprise-redhat-ubi9?label=codercom%2Fenterprise-redhat-ubi9)](https://hub.docker.com/r/codercom/enterprise-redhat-ubi9)

## Description

A minimal base image based on Red Hat Universal Base Image 9 (UBI9) for use with Coder workspaces. This image provides enterprise-grade security and compliance while maintaining a minimal footprint.

## Features

### Base Operating System

- **Red Hat UBI9**: Enterprise-grade, security-focused base image
- **Enterprise Ready**: Red Hat supported with regular security updates
- **Compliance**: Meets enterprise security and compliance requirements
- **Minimal**: Only essential packages included

### Included Tools

#### Essential Development Tools

- **Development Tools**: GCC, make, and essential build tools
- **Docker CE**: Container development and deployment
- **Git**: Version control
- **Python 3**: System Python with pip
- **Bash**: Default shell

#### System Utilities

- **curl/wget**: HTTP clients
- **jq**: JSON processing
- **htop**: Process monitoring
- **vim**: Text editor
- **unzip**: Archive extraction
- **rsync**: File synchronization
- **systemd**: System and service manager

## Usage

### With Coder Templates

Use this image as a base in your Coder workspace templates:

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

### Extending This Image

Extend this image with additional tooling and language packages:

```dockerfile
FROM codercom/enterprise-redhat-ubi9

# Install Go
RUN curl -L "https://go.dev/dl/go1.24.2.linux-amd64.tar.gz" | tar -C /usr/local -xz
ENV PATH=/usr/local/go/bin:$PATH

# Install Node.js
RUN curl -fsSL https://rpm.nodesource.com/setup_20.x | bash - && \
    dnf install -y nodejs

# Add your tools here
```

### Building Locally

```bash
# Build the image
docker build -f ubi9.Dockerfile -t coder-redhat-ubi9 .

# Run interactively
docker run -it --rm coder-redhat-ubi9
```

## How To Use It

Extend this image with additional tooling and language packages.

### Environment Variables

The image sets up the following environment:

- `LANG=en_US.UTF-8`
- `LANGUAGE=en_US.UTF-8`
- `LC_ALL=en_US.UTF-8`

### User Configuration

- **User**: `coder` (non-root)
- **Home**: `/home/coder`
- **Shell**: bash
- **Sudo**: Passwordless sudo access
- **Groups**: docker (for Docker access)

## Use Cases

This base image is ideal for:

- **Enterprise Environments**: Red Hat compliance and support
- **Container Development**: Docker and containerized applications
- **Custom Development Images**: Extend with specific language runtimes
- **Security-Conscious Deployments**: Minimal attack surface
- **Compliance Requirements**: Red Hat enterprise support

## Security & Compliance

- Based on Red Hat UBI9 for enterprise security
- Regular security updates from Red Hat
- Non-root user execution
- Minimal package installation
- Compliance with enterprise security policies

## Support

For issues related to:

- **This image**: Open an issue in the [coder/images](https://github.com/coder/images) repository
- **Coder platform**: Visit [coder.com/docs](https://coder.com/docs)
- **Red Hat UBI9**: Check [Red Hat documentation](https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/9)

## License

This image configuration is provided under the same license as the Coder project.
Red Hat UBI9 is freely redistributable under Red Hat's Universal Base Image End User License Agreement.
