FROM codercom/example-base:ubuntu

# Run everything as root
USER root

# Install go
RUN curl -L "https://go.dev/dl/go1.20.linux-amd64.tar.gz" | tar -C /usr/local -xzvf -

# Setup go env vars
ENV GOROOT=/usr/local/go
ENV PATH=$PATH:$GOROOT/bin

ENV GOPATH=/home/coder/go
ENV GOBIN=$GOPATH/bin
ENV PATH=$PATH:$GOBIN

# Set back to coder user
USER coder
