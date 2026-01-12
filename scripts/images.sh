#!/usr/bin/env bash

set -euo pipefail

# IMAGES defines the list of images to build/push IN ORDER.
IMAGES=(
  "base"
  "minimal"
  "golang"
  "java"
  "node"
  "desktop"
)
