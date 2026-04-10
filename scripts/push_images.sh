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
REGISTRY="dockerhub"

function usage() {
  echo "Usage: $(basename "$0") [options]"
  echo
  echo "This script pushes Coder's container images to a registry."
  echo
  echo "Options:"
  echo " -h, --help                   Show this help text and exit"
  echo " --dry-run                    Show commands that would run, but"
  echo "                              do not run them"
  echo " --tag=<tag>                  Select an image tag group to build,"
  echo "                              e.g. ubuntu)"
  echo " --quiet                      Suppress container build output"
  echo " --registry=<registry>        Target registry: dockerhub (default)"
  echo "                              or ghcr.io"
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
                quiet, \
                registry:" \
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
  --registry)
    shift
    REGISTRY="$1"
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

if [ $QUIET = true ]; then
  docker_flags+=(
    --quiet
  )
fi

date_str=$(date --utc +%Y%m%d)
for image in "${IMAGES[@]}"; do
  image_dir="$PROJECT_ROOT/images/$image"
  image_file="${TAG}.Dockerfile"
  image_path="$image_dir/$image_file"

  if [ ! -f "$image_path" ]; then
    if [ $QUIET = false ]; then
      echo "Path '$image_path' does not exist; skipping" >&2
    fi
    continue
  fi

  build_id=$(cat "build_${image}.json" | jq -r .\[\"depot.build\"\].buildID)

  if [ "$REGISTRY" = "ghcr.io" ]; then
    # Push to GHCR with new naming: ghcr.io/coder/$TAG:$IMAGE
    ghcr_ref="ghcr.io/coder/${TAG}:${image}"
    ghcr_ref_date="ghcr.io/coder/${TAG}:${image}-${date_str}"

    run_trace $DRY_RUN depot push --project "gb3p8xrshk" --tag "$ghcr_ref" "$build_id"
    run_trace $DRY_RUN depot push --project "gb3p8xrshk" --tag "$ghcr_ref_date" "$build_id"
  else
    # Push to Docker Hub (default, existing behavior)
    enterprise_image_ref="codercom/enterprise-$image:$TAG"
    enterprise_image_ref_date="${enterprise_image_ref}-${date_str}"
    example_image_ref="codercom/example-$image:$TAG"
    example_image_ref_date="${example_image_ref}-${date_str}"

    # Push example images (primary)
    run_trace $DRY_RUN depot push --project "gb3p8xrshk" --tag "$example_image_ref" "$build_id"
    run_trace $DRY_RUN depot push --project "gb3p8xrshk" --tag "$example_image_ref_date" "$build_id"
    run_trace $DRY_RUN depot push --project "gb3p8xrshk" --tag "codercom/example-${image}:latest" "$build_id"

    # Push enterprise images (alias)
    run_trace $DRY_RUN depot push --project "gb3p8xrshk" --tag "$enterprise_image_ref" "$build_id"
    run_trace $DRY_RUN depot push --project "gb3p8xrshk" --tag "$enterprise_image_ref_date" "$build_id"
    run_trace $DRY_RUN depot push --project "gb3p8xrshk" --tag "codercom/enterprise-${image}:latest" "$build_id"
  fi
done
