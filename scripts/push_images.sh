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
  echo "This script pushes Coder's container images to Docker Hub."
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

if [ $QUIET = true ]; then
  docker_flags+=(
    --quiet
  )
fi

date_str=$(date --utc +%Y%m%d)
for image in "${IMAGES[@]}"; do
  image_dir="$PROJECT_ROOT/images/$image"
  image_file="${TAG}.Dockerfile"
  image_ref="codercom/enterprise-$image:$TAG"
  image_ref_date="${image_ref}-${date_str}"
  image_path="$image_dir/$image_file"

  if [ ! -f "$image_path" ]; then
    if [ $QUIET = false ]; then
      echo "Path '$image_path' does not exist; skipping" >&2
    fi
    continue
  fi

  build_id=$(cat "build_${image}.json" | jq -r .\[\"depot.build\"\].buildID)
  run_trace $DRY_RUN depot push --project "gb3p8xrshk" --tag "$image_ref" "$build_id"
  run_trace $DRY_RUN depot push --project "gb3p8xrshk" --tag "$image_ref_date" "$build_id"
  run_trace $DRY_RUN depot push --project "gb3p8xrshk" --tag "codercom/enterprise-${image}:latest" "$build_id"
  
  # For Ubuntu images, also push version-specific tags
  if [ "$TAG" = "ubuntu" ]; then
    # Extract Ubuntu version from Dockerfile
    ubuntu_base=$(grep "^FROM ubuntu:" "$image_path" | head -1 | cut -d: -f2)
    if [ -n "$ubuntu_base" ]; then
      # Map Ubuntu codenames to version numbers
      case "$ubuntu_base" in
        "noble")
          ubuntu_version="24.04"
          ;;
        "jammy")
          ubuntu_version="22.04"
          ;;
        "focal")
          ubuntu_version="20.04"
          ;;
        *)
          # If it's already a version number, use it directly
          if [[ "$ubuntu_base" =~ ^[0-9]+\.[0-9]+$ ]]; then
            ubuntu_version="$ubuntu_base"
            # Map version numbers to codenames
            case "$ubuntu_version" in
              "24.04")
                ubuntu_codename="noble"
                ;;
              "22.04")
                ubuntu_codename="jammy"
                ;;
              "20.04")
                ubuntu_codename="focal"
                ;;
            esac
          else
            ubuntu_version=""
          fi
          ;;
      esac
      
      # Push version-specific tags
      if [ -n "$ubuntu_version" ]; then
        version_tag="codercom/enterprise-$image:ubuntu-$ubuntu_version"
        run_trace $DRY_RUN depot push --project "gb3p8xrshk" --tag "$version_tag" "$build_id"
        if [ $QUIET = false ]; then
          echo "Pushed Ubuntu version tag: ubuntu-$ubuntu_version" >&2
        fi
      fi
      
      # Push codename tag if we have one
      if [ -n "${ubuntu_codename:-}" ] || [ "$ubuntu_base" != "$ubuntu_version" ]; then
        codename="${ubuntu_codename:-$ubuntu_base}"
        codename_tag="codercom/enterprise-$image:ubuntu-$codename"
        run_trace $DRY_RUN depot push --project "gb3p8xrshk" --tag "$codename_tag" "$build_id"
        if [ $QUIET = false ]; then
          echo "Pushed Ubuntu codename tag: ubuntu-$codename" >&2
        fi
      fi
    fi
  fi
done
