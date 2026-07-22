#!/usr/bin/env bash

set -euo pipefail

# UBUNTU_VERSION defines the Ubuntu release used as the base for all
# images. Changing this value and rebuilding will produce images on
# a different Ubuntu release. All Dockerfiles and the push script
# read this variable so it acts as a single source of truth.
UBUNTU_VERSION="resolute"

# IMAGES defines the list of images to build/push IN ORDER.
IMAGES=(
  "base"
  "minimal"
  "golang"
  "java"
  "node"
  "desktop"
  "universal"
)
