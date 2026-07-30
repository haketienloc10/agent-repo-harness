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
require_file "$workspace_root/identity.md"
require_file "$workspace_root/SYSTEM_MAP.md"
require_file "$workspace_root/repos.yaml"
require_file "$workspace_root/instructions/model-routing.md"
require_file "$workspace_root/.agents/skills/herdr/SKILL.md"
require_file "$workspace_root/.agents/skills/herdr/LICENSE.txt"
require_file "$workspace_root/.agents/skills/herdr/SOURCE.md"
require_file "$workspace_root/docs/WORKSPACE_SETUP.md"

managed_files=(
  "$workspace_root/AGENTS.md"
  "$workspace_root/identity.md"
  "$workspace_root/SYSTEM_MAP.md"
  "$workspace_root/repos.yaml"
  "$workspace_root/instructions/model-routing.md"
)

existing_managed_files=()
for path in "${managed_files[@]}"; do
  [[ -f "$path" ]] && existing_managed_files+=("$path")
done

if ((${#existing_managed_files[@]} > 0)) && rg -n '\{\{[^}]+\}\}' "${existing_managed_files[@]}"; then
  fail 'unresolved placeholder(s) found; replace every template value'
fi

herdr_skill="$workspace_root/.agents/skills/herdr/SKILL.md"
herdr_license="$workspace_root/.agents/skills/herdr/LICENSE.txt"
herdr_source="$workspace_root/.agents/skills/herdr/SOURCE.md"

if [[ -f "$herdr_skill" ]]; then
  rg -q '^---$' "$herdr_skill" || fail '.agents/skills/herdr/SKILL.md: missing YAML frontmatter fence'
  rg -q '^name:[[:space:]]+herdr$' "$herdr_skill" || \
    fail '.agents/skills/herdr/SKILL.md: frontmatter name must be herdr'
  rg -q '^description:.*Herdr' "$herdr_skill" || \
    fail '.agents/skills/herdr/SKILL.md: description must identify Herdr'
  rg -q 'HERDR_ENV=1' "$herdr_skill" || \
    fail '.agents/skills/herdr/SKILL.md: must require HERDR_ENV=1'
fi

if [[ -f "$herdr_license" ]]; then
  rg -q 'Apache License' "$herdr_license" || \
    fail '.agents/skills/herdr/LICENSE.txt: expected Apache License text'
  rg -q 'Version 2\.0' "$herdr_license" || \
    fail '.agents/skills/herdr/LICENSE.txt: expected Apache License Version 2.0'
fi

if [[ -f "$herdr_source" ]]; then
  rg -q 'https://github\.com/ogulcancelik/herdr' "$herdr_source" || \
    fail '.agents/skills/herdr/SOURCE.md: missing upstream repository'
  rg -q 'Upstream commit' "$herdr_source" || \
    fail '.agents/skills/herdr/SOURCE.md: missing pinned upstream commit'
  rg -q 'Local modifications' "$herdr_source" || \
    fail '.agents/skills/herdr/SOURCE.md: missing local-modification status'
fi

if [[ -f "$workspace_root/AGENTS.md" ]]; then
  rg -q '`identity\.md`' "$workspace_root/AGENTS.md" || \
    fail 'AGENTS.md: must route QiQi to identity.md'
  rg -q '`instructions/model-routing\.md`' "$workspace_root/AGENTS.md" || \
    fail 'AGENTS.md: must route QiQi to instructions/model-routing.md'
  rg -q '`\.agents/skills/herdr/SKILL\.md`' "$workspace_root/AGENTS.md" || \
    fail 'AGENTS.md: must route QiQi to the bundled Herdr skill'
  rg -q 'HERDR_ENV=1' "$workspace_root/AGENTS.md" || \
    fail 'AGENTS.md: must require HERDR_ENV=1 before Herdr control'
fi

if [[ -f "$workspace_root/instructions/model-routing.md" ]]; then
  rg -q 'Điểm mạnh' "$workspace_root/instructions/model-routing.md" || \
    fail 'instructions/model-routing.md: missing model strengths'
  rg -q 'Điểm yếu' "$workspace_root/instructions/model-routing.md" || \
    fail 'instructions/model-routing.md: missing model weaknesses'
  rg -q 'Model ID' "$workspace_root/instructions/model-routing.md" || \
    fail 'instructions/model-routing.md: missing exact model ID inventory'
  rg -q 'Agent kind' "$workspace_root/instructions/model-routing.md" || \
    fail 'instructions/model-routing.md: missing Herdr agent kind inventory'
  rg -q 'Native arguments' "$workspace_root/instructions/model-routing.md" || \
    fail 'instructions/model-routing.md: missing native agent arguments'
  rg -q 'fast' "$workspace_root/instructions/model-routing.md" || \
    fail 'instructions/model-routing.md: missing fast profile'
  rg -q 'balanced' "$workspace_root/instructions/model-routing.md" || \
    fail 'instructions/model-routing.md: missing balanced profile'
  rg -q 'deep' "$workspace_root/instructions/model-routing.md" || \
    fail 'instructions/model-routing.md: missing deep profile'
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
