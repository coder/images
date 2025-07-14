#!/usr/bin/env bash

set -euo pipefail

# Avoid using cd because we accept paths as arguments to this script.

source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

check_dependencies \
  docker \
  trivy \
  jq

source "$(dirname "${BASH_SOURCE[0]}")/images.sh"

PROJECT_ROOT="$(git rev-parse --show-toplevel)"
TAG="ubuntu"
OUTPUT_FILE=""
DRY_RUN=false

function usage() {
  echo "Usage: $(basename "$0") [options]"
  echo
  echo "This script scans Coder's container images."
  echo
  echo "Options:"
  echo " -h, --help                   Show this help text and exit"
  echo " --dry-run                    Show commands that would run, but"
  echo "                              do not run them"
  echo " --tag=<tag>                  Select an image tag group to build,"
  echo "                              e.g. ubuntu)"
  echo " --output-file=<path>         File path to write merged SARIF file to"
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
                output-file:, \
                upload" \
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
  --output-file)
    shift
    OUTPUT_FILE="$1"
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

if [ -z "${OUTPUT_FILE:-}" ]; then
  echo "Output file must be specified" >&2
  usage
fi
OUTPUT_FILE="$(realpath "$OUTPUT_FILE")"
mkdir -p "$(dirname "$OUTPUT_FILE")"
if [ -e "$OUTPUT_FILE" ]; then
  echo "Output file '$OUTPUT_FILE' already exists" >&2
  exit 1
fi

tmp_dir="$(mktemp -d)"

# Trivy copies images to /tmp, so we need to set TMPDIR to a dir in the
# workspace dir to avoid running out of tmpfs space (which happens in CI).
trivy_tmp_dir="$(mktemp -d -p "$PROJECT_ROOT")"

trap 'rm -rf "$tmp_dir" "$trivy_tmp_dir"' EXIT

PREFIXES=("example" "enterprise")

for image in "${IMAGES[@]}"; do
  for prefix in "${PREFIXES[@]}"; do
    image_ref="codercom/${prefix}-${image}:${TAG}"
    image_name="${prefix}-${image}-${TAG}"
    output="${tmp_dir}/${prefix}-${image}-${TAG}.sarif"

    if ! docker image inspect "$image_ref" >/dev/null 2>&1; then
      echo "Image '$image_ref' does not exist locally; skipping" >&2
      continue
    fi

    old_tmpdir="${TMPDIR:-}"
    export TMPDIR="$trivy_tmp_dir"

    # The timeout is set to 15 minutes because in Java images it can take a while
    # to scan JAR files for vulnerabilities.
    run_trace $DRY_RUN trivy image \
      --severity CRITICAL,HIGH \
      --format sarif \
      --output "$output" \
      --timeout 15m0s \
      "$image_ref" 2>&1 | indent

    if [ "$old_tmpdir" = "" ]; then
      unset TMPDIR
    else
      export TMPDIR="$old_tmpdir"
    fi

    if [ $DRY_RUN = true ]; then
      continue
    fi

    if [ ! -f "$output" ]; then
      echo "No SARIF output found for image '$image_ref' at '$output'" >&2
      exit 1
    fi

    # Do substitutions to add extra details to every message. Without these
    # substitutions, most messages won't have any information about which image
    # the vulnerability was found in.
    jq \
      ".runs[].tool.driver.name |= \"Trivy ${image_name}\"" \
      "$output" >"$output.tmp"
    mv "$output.tmp" "$output"
    jq \
      ".runs[].results[].locations[].physicalLocation.artifactLocation.uri |= \"${image_name}/\" + ." \
      "$output" >"$output.tmp"
    mv "$output.tmp" "$output"
    jq \
      ".runs[].results[].locations[].message.text |= \"${image_name}: \" + ." \
      "$output" >"$output.tmp"
    mv "$output.tmp" "$output"
  done
done

# Merge all SARIF files into one.
jq -s \
  'reduce .[] as $item ([]; . + $item.runs) | { "version": "2.1.0", "$schema": "https://json.schemastore.org/sarif-2.1.0-rtm.5.json", "runs": . }' \
  "$tmp_dir"/*.sarif >"$OUTPUT_FILE"
