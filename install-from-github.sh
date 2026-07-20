#!/usr/bin/env bash

set -euo pipefail

HARNESS_REPOSITORY="${HARNESS_REPOSITORY:-haketienloc10/agent-repo-harness}"
HARNESS_REF="${HARNESS_REF:-main}"
GITHUB_ARCHIVE_BASE_URL="${GITHUB_ARCHIVE_BASE_URL:-https://github.com}"

usage() {
  cat <<'USAGE'
Usage: curl -fsSL https://raw.githubusercontent.com/haketienloc10/agent-repo-harness/main/install-from-github.sh | bash -s -- --target /path/to/repo [--dry-run] [--overwrite]

Downloads the harness source archive from GitHub and delegates to install.sh.

Environment:
  HARNESS_REPOSITORY       GitHub repository in OWNER/REPO form.
                           Default: haketienloc10/agent-repo-harness
  HARNESS_REF              Branch, tag, or commit SHA to install.
                           Default: main
  GITHUB_ARCHIVE_BASE_URL  GitHub base URL. Intended for testing or GitHub Enterprise.
                           Default: https://github.com
USAGE
}

fail() {
  printf 'Error: %s\n' "$1" >&2
  exit 1
}

case "${1:-}" in
  -h|--help)
    usage
    exit 0
    ;;
esac

[[ "$HARNESS_REPOSITORY" =~ ^[A-Za-z0-9._-]+/[A-Za-z0-9._-]+$ ]] || \
  fail "HARNESS_REPOSITORY must use OWNER/REPO form."
[[ "$HARNESS_REF" =~ ^[A-Za-z0-9._/-]+$ && "$HARNESS_REF" != . && "$HARNESS_REF" != ./* && \
  "$HARNESS_REF" != */. && "$HARNESS_REF" != .. && "$HARNESS_REF" != ../* && \
  "$HARNESS_REF" != */../* && "$HARNESS_REF" != */.. ]] || \
  fail "HARNESS_REF contains unsupported characters."
command -v curl >/dev/null 2>&1 || fail "curl is required."
command -v tar >/dev/null 2>&1 || fail "tar is required."

temporary_dir="$(mktemp -d)" || fail "cannot create temporary directory."
cleanup() {
  rm -rf -- "$temporary_dir"
}
trap cleanup EXIT

archive_path="$temporary_dir/harness.tar.gz"
source_dir="$temporary_dir/source"
archive_url="${GITHUB_ARCHIVE_BASE_URL%/}/${HARNESS_REPOSITORY}/archive/${HARNESS_REF}.tar.gz"

printf 'Downloading harness from %s at ref %s...\n' "$HARNESS_REPOSITORY" "$HARNESS_REF"
curl --fail --location --silent --show-error --retry 3 --output "$archive_path" "$archive_url" || \
  fail "could not download harness archive: $archive_url"

mkdir -p -- "$source_dir"
tar -xzf "$archive_path" -C "$source_dir" --strip-components=1 || \
  fail "downloaded archive is not a valid harness source archive."
[[ -f "$source_dir/install.sh" ]] || fail "downloaded archive does not contain install.sh."
[[ -f "$source_dir/.harness-required-files" ]] || fail "downloaded archive is missing .harness-required-files."
[[ -d "$source_dir/repo-template" ]] || fail "downloaded archive is missing repo-template."

printf 'Running installer...\n'
bash "$source_dir/install.sh" "$@"
