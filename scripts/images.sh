#!/usr/bin/env bash

set -euo pipefail

# UBUNTU_VERSION defines the Ubuntu release used as the base for all
# images. Changing this value and rebuilding will produce images on
# a different Ubuntu release. All Dockerfiles and the push script
# read this variable so it acts as a single source of truth.
UBUNTU_VERSION="resolute"

# UBUNTU_VERSION_OVERRIDES pins individual images to a different Ubuntu
# release than the default UBUNTU_VERSION above. It drives both the build
# arg and the version-specific push tags, so an overridden image is tagged
# with the release it is actually built from rather than the default.
#
# universal is pinned to noble because Microsoft's devcontainers/universal
# image does not yet publish a resolute (26.04) tag. See coder/images#335.
declare -A UBUNTU_VERSION_OVERRIDES=(
  ["universal"]="noble"
)

# ubuntu_version_for prints the Ubuntu release for the given image, using an
# override when present and falling back to the default UBUNTU_VERSION.
ubuntu_version_for() {
  local image="$1"
  echo "${UBUNTU_VERSION_OVERRIDES[$image]:-$UBUNTU_VERSION}"
}

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
