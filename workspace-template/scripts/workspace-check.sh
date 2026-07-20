#!/usr/bin/env bash
set -euo pipefail

workspace_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
errors=0

fail() {
  printf 'FAIL: %s\n' "$*" >&2
  errors=$((errors + 1))
}

require_file() {
  local path="$1"
  [[ -f "$path" ]] || fail "missing file: ${path#$workspace_root/}"
}

require_file "$workspace_root/AGENTS.md"
require_file "$workspace_root/SYSTEM_MAP.md"
require_file "$workspace_root/repos.yaml"
require_file "$workspace_root/docs/WORKSPACE_SETUP.md"

if rg -n '\{\{[^}]+\}\}' \
  "$workspace_root/AGENTS.md" \
  "$workspace_root/SYSTEM_MAP.md" \
  "$workspace_root/repos.yaml"; then
  fail 'unresolved placeholder(s) found; replace every template value'
fi

if ! command -v yq >/dev/null 2>&1; then
  fail 'missing required command: yq version 4 (needed to validate repos.yaml)'
elif ! yq --version 2>&1 | rg -q 'version v?4\.'; then
  fail 'unsupported yq version; install yq version 4'
else
  if ! yq -e '.workspace.name | type == "!!str" and length > 0' "$workspace_root/repos.yaml" >/dev/null; then
    fail 'repos.yaml: workspace.name must be a non-empty string'
  fi

  if ! yq -e '.repositories | type == "!!seq" and length > 0' "$workspace_root/repos.yaml" >/dev/null; then
    fail 'repos.yaml: repositories must be a non-empty list'
  else
    mapfile -t repository_names < <(yq -r '.repositories[].name' "$workspace_root/repos.yaml")
    mapfile -t repository_paths < <(yq -r '.repositories[].path' "$workspace_root/repos.yaml")

    for index in "${!repository_names[@]}"; do
      name="${repository_names[$index]}"
      path="${repository_paths[$index]}"
      [[ -n "$name" && "$name" != "null" ]] || fail 'repos.yaml: repository name is empty'
      [[ -n "$path" && "$path" != "null" ]] || fail "repos.yaml: ${name}: path is empty"
      [[ "$path" != /* ]] || fail "repos.yaml: ${name}: path must be relative"
      [[ "$path" != *'..'* ]] || fail "repos.yaml: ${name}: path must not contain .."

      module_root="$workspace_root/$path"
      if ! git -C "$module_root" rev-parse --show-toplevel >/dev/null 2>&1; then
        fail "repos.yaml: ${name}: path is not a Git repository: $path"
        continue
      fi
      git_root="$(git -C "$module_root" rev-parse --show-toplevel)"
      [[ "$git_root" == "$module_root" ]] || fail "repos.yaml: ${name}: path must be the Git root: $path"
    done

    duplicate_names="$(printf '%s\n' "${repository_names[@]}" | sort | uniq -d)"
    [[ -z "$duplicate_names" ]] || fail "repos.yaml: duplicate repository name(s): $duplicate_names"
  fi
fi

if [[ "$errors" -gt 0 ]]; then
  printf 'workspace-check: FAIL (%d error(s))\n' "$errors" >&2
  exit 1
fi

printf 'workspace-check: PASS\n'
