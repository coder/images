#!/usr/bin/env bash

set -euo pipefail

cd "$(dirname "$0")"
source "./lib.sh"

check_dependencies \
  docker \
  depot

source "./images.sh"

PROJECT_ROOT="$(git rev-parse --show-toplevel)"
TAG="ubuntu"
DRY_RUN=false
QUIET=false

function usage() {
  echo "Usage: $(basename "$0") [options]"
  echo
  echo "This script builds Coder's container images."
  echo
  echo "Options:"
  echo " -h, --help                   Show this help text and exit"
  echo " --dry-run                    Show commands that would run, but"
  echo "                              do not run them"
  echo " --tag=<tag>                  Select an image tag group to build,"
  echo "                              e.g. ubuntu)"
  echo " --quiet                      Suppress container build output"
  exit 1
}

# Allow a failing exit status, as user input can cause this
set +o errexit
options=$(getopt \
            --name="$(basename "$0")" \
            --longoptions=" \
                help, \
                dry-run, \
                tag:, \
                quiet" \
            --options="h" \
            -- "$@")
# allow checking the exit code separately here, because we need both
# the response data and the exit code
# shellcheck disable=SC2181
if [ $? -ne 0 ]; then
  usage
fi
set -o errexit

eval set -- "$options"
while true; do
  case "${1:-}" in
  --dry-run)
    DRY_RUN=true
    ;;
  --tag)
    shift
    TAG="$1"
    ;;
  --quiet)
    QUIET=true
    ;;
  -h|--help)
    usage
    ;;
  --)
    shift
    break
    ;;
  *)
    # Default case, print an error and quit. This code shouldn't be
    # reachable, because getopt should return an error exit code.
    echo "Unknown option: $1"
    usage
    ;;
  esac
  shift
done

docker_flags=()

if [ "$QUIET" = true ]; then
  docker_flags+=(
    --quiet
  )
fi

for image in "${IMAGES[@]}"; do
  image_dir="$PROJECT_ROOT/images/$image"
  image_file="${TAG}.Dockerfile"
  enterprise_image_ref="codercom/enterprise-$image:$TAG"
  example_image_ref="codercom/example-$image:$TAG"
  image_path="$image_dir/$image_file"
  platforms="linux/arm64,linux/amd64,linux/arm/v7"

  if [ ! -f "$image_path" ]; then
    if [ "$QUIET" = false ]; then
      echo "Path '$image_path' does not exist; skipping" >&2
    fi
    continue
  fi

  if [[ "$image" == "java-sdkman" ]]; then
    platforms="linux/arm64,linux/amd64"
  fi

  run_trace $DRY_RUN depot build \
      --load \
      --platform "$platforms" \
      --save \
      --metadata-file="build_${image}.json" \
    "${docker_flags[@]}" \
    "$image_dir" \
    --file="$image_path" \
    --tag="$example_image_ref" \
    --tag="$enterprise_image_ref" \| indent
done
