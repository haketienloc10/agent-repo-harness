#!/usr/bin/env bash

set -u
set -o pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
REPO_ROOT="$(cd -- "$SCRIPT_DIR/.." && pwd -P)"
MANIFEST_PATH="$REPO_ROOT/.harness-required-files"
fail_count=0

report() {
  local status="$1"
  local check="$2"
  local message="$3"

  printf '%s [%s] %s\n' "$status" "$check" "$message"
  if [[ "$status" == "FAIL" ]]; then
    ((fail_count += 1))
  fi
}

trim_value() {
  local value="$1"
  value="${value#*:\ }"
  value="${value//\`/}"
  value="${value#${value%%[![:space:]]*}}"
  value="${value%${value##*[![:space:]]}}"
  printf '%s' "$value"
}

field_value() {
  local file="$1"
  local label="$2"
  local line

  line="$(grep -m1 -E "^[[:space:]]*-[[:space:]]+${label}:[[:space:]]*" "$file" 2>/dev/null || true)"
  trim_value "$line"
}

is_configured_value() {
  local value="$1"
  [[ -n "$value" && ! "$value" =~ \{\{[A-Z0-9_]+\}\} ]]
}

emit_harness_files() {
  local path
  local active_dir="$REPO_ROOT/docs/exec-plans/active"

  if [[ -f "$MANIFEST_PATH" ]]; then
    while IFS= read -r path || [[ -n "$path" ]]; do
      [[ -z "$path" || "$path" == \#* || ! -f "$REPO_ROOT/$path" ]] && continue
      printf '%s\0' "$REPO_ROOT/$path"
    done < "$MANIFEST_PATH"
  fi

  if [[ -d "$active_dir" ]]; then
    find "$active_dir" -maxdepth 1 -type f -name '*.md' ! -name 'index.md' -print0
  fi
}

check_required_files() {
  local path
  local missing=0

  if [[ ! -f "$MANIFEST_PATH" ]]; then
    report FAIL required-files ".harness-required-files is missing; required files cannot be checked."
    return
  fi

  while IFS= read -r path || [[ -n "$path" ]]; do
    [[ -z "$path" || "$path" == \#* ]] && continue
    if [[ ! -f "$REPO_ROOT/$path" ]]; then
      report FAIL required-files "$path is missing."
      missing=1
    fi
  done < "$MANIFEST_PATH"

  if ((missing == 0)); then
    report PASS required-files "All files listed in .harness-required-files exist."
  fi
}

check_placeholders() {
  local file
  local matches
  local found=0

  while IFS= read -r -d '' file; do
    matches="$(grep -nE '\{\{[A-Z0-9_]+\}\}' "$file" 2>/dev/null || true)"
    if [[ -n "$matches" ]]; then
      while IFS= read -r match; do
        report FAIL placeholders "${file#"$REPO_ROOT/"}:$match"
      done <<< "$matches"
      found=1
    fi
  done < <(emit_harness_files)

  if ((found == 0)); then
    report PASS placeholders "No required placeholder remains in managed files."
  fi
}

check_baseline() {
  local file="$REPO_ROOT/docs/PROJECT_BASELINE.md"
  local date_value
  local revision_value

  [[ -f "$file" ]] || return
  date_value="$(field_value "$file" "Ngày baseline")"
  revision_value="$(field_value "$file" "Git revision")"

  if [[ "$date_value" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
    report PASS baseline-date "docs/PROJECT_BASELINE.md records baseline date $date_value."
  else
    report FAIL baseline-date "docs/PROJECT_BASELINE.md must contain '- Ngày baseline: YYYY-MM-DD'."
  fi

  if [[ "$revision_value" =~ ^[0-9a-fA-F]{7,64}$ ]]; then
    report PASS baseline-revision "docs/PROJECT_BASELINE.md records revision $revision_value."
  else
    report FAIL baseline-revision "docs/PROJECT_BASELINE.md must contain a 7-64 character hexadecimal Git revision."
  fi
}

check_commands() {
  local file="$REPO_ROOT/docs/RELIABILITY.md"
  local label
  local value
  local invalid=0

  [[ -f "$file" ]] || return
  for label in "Bootstrap" "Xác minh" "Khởi động app hoặc service"; do
    value="$(field_value "$file" "$label")"
    if is_configured_value "$value"; then
      report PASS commands "docs/RELIABILITY.md configures $label."
    else
      report FAIL commands "docs/RELIABILITY.md has no configured value for '$label'."
      invalid=1
    fi
  done

  return "$invalid"
}

check_active_plan() {
  local active_dir="$REPO_ROOT/docs/exec-plans/active"
  local plan

  [[ -d "$active_dir" ]] || return
  plan="$(find "$active_dir" -maxdepth 1 -type f -name '*.md' ! -name 'index.md' -size +0c -print -quit)"
  if [[ -n "$plan" ]]; then
    report PASS active-plan "Active execution plan found: ${plan#"$REPO_ROOT/"}."
  else
    report FAIL active-plan "docs/exec-plans/active must contain at least one Markdown plan besides index.md."
  fi
}

check_markdown_links() {
  local file
  local token
  local target
  local resolved
  local broken=0

  while IFS= read -r -d '' file; do
    [[ "$file" == *.md ]] || continue
    while IFS= read -r token; do
      [[ -n "$token" ]] || continue
      target="${token#\](}"
      target="${target#<}"
      target="${target%%>*}"
      target="${target%%[[:space:]]*}"
      [[ -n "$target" ]] || continue
      case "$target" in
        \#*|/*|*://*|mailto:*|tel:*) continue ;;
      esac
      target="${target%%\#*}"
      target="${target%%\?*}"
      [[ -n "$target" ]] || continue
      resolved="$(dirname -- "$file")/$target"
      if [[ ! -e "$resolved" ]]; then
        report FAIL markdown-links "${file#"$REPO_ROOT/"} points to missing relative target '$target'."
        broken=1
      fi
    done < <(grep -oE '\]\([^)]+' "$file" 2>/dev/null || true)
  done < <(emit_harness_files)

  if ((broken == 0)); then
    report PASS markdown-links "All Markdown relative links resolve."
  fi
}

check_legacy_issues() {
  local file="$REPO_ROOT/docs/LEGACY_ISSUES.md"
  local baseline_file="$REPO_ROOT/docs/PROJECT_BASELINE.md"
  local baseline_revision=""
  local heading_data
  local -a headings=()
  local index
  local line_number
  local heading
  local next_line
  local section
  local id
  local value
  local invalid
  local heading_pattern='^###[[:space:]]+`?(LEGACY-[0-9]{3})`?[[:space:]]*:'

  [[ -f "$file" ]] || return
  [[ -f "$baseline_file" ]] && baseline_revision="$(field_value "$baseline_file" "Git revision")"
  mapfile -t headings < <(grep -nE '^###[[:space:]]+' "$file" || true)

  if ((${#headings[@]} == 0)); then
    report PASS legacy-issues "No legacy issue is recorded."
    return
  fi

  for ((index = 0; index < ${#headings[@]}; index += 1)); do
    heading_data="${headings[$index]}"
    line_number="${heading_data%%:*}"
    heading="${heading_data#*:}"
    if ((index + 1 < ${#headings[@]})); then
      next_line="${headings[$((index + 1))]%%:*}"
      section="$(sed -n "${line_number},$((next_line - 1))p" "$file")"
    else
      section="$(sed -n "${line_number},\$p" "$file")"
    fi

    if [[ "$heading" =~ $heading_pattern ]]; then
      id="${BASH_REMATCH[1]}"
    else
      report FAIL legacy-issues "docs/LEGACY_ISSUES.md:$line_number has an issue heading without an ID matching LEGACY-NNN."
      continue
    fi

    invalid=0
    for label in "Failure signature" "Baseline revision" "Baseline evidence" "Reproduction command / steps"; do
      value="$(trim_value "$(grep -m1 -E "^[[:space:]]*-[[:space:]]+${label}:[[:space:]]*" <<< "$section" || true)")"
      if ! is_configured_value "$value"; then
        report FAIL legacy-issues "$id has no configured '$label'."
        invalid=1
      elif [[ "$label" == "Baseline revision" && -n "$baseline_revision" && "$value" != "$baseline_revision" ]]; then
        report FAIL legacy-issues "$id references baseline revision '$value', expected '$baseline_revision'."
        invalid=1
      fi
    done

    value="$(trim_value "$(grep -m1 -E '^[[:space:]]*-[[:space:]]+Status:[[:space:]]*' <<< "$section" || true)")"
    if [[ "$value" != "Accepted" && "$value" != "In progress" && "$value" != "Resolved" ]]; then
      report FAIL legacy-issues "$id has invalid Status '$value'."
      invalid=1
    fi

    if ((invalid == 0)); then
      report BASELINE legacy-issues "$id is documented with evidence at revision $baseline_revision."
    fi
  done
}

check_product_spec_index() {
  local index_file="$REPO_ROOT/docs/product-specs/index.md"
  local target
  local found=0
  local broken=0

  [[ -f "$index_file" ]] || return
  while IFS= read -r target; do
    [[ -n "$target" ]] || continue
    found=1
    if [[ ! -f "$(dirname -- "$index_file")/$target" ]]; then
      report FAIL product-spec-index "docs/product-specs/index.md points to missing spec '$target'."
      broken=1
    fi
  done < <(grep -oE '[A-Za-z0-9._/-]+\.md' "$index_file" | sort -u || true)

  if ((found == 0)); then
    report WARN product-spec-index "docs/product-specs/index.md does not list a Markdown spec."
  elif ((broken == 0)); then
    report PASS product-spec-index "All specs named by docs/product-specs/index.md exist."
  fi
}

check_quality_score() {
  local file="$REPO_ROOT/docs/QUALITY_SCORE.md"

  [[ -f "$file" ]] || return
  if grep -Eq '^\|.*\|[[:space:]]*`?[A-D]`?[[:space:]]*\|' "$file"; then
    report PASS quality-score "docs/QUALITY_SCORE.md contains at least one initialized A-D score."
  else
    report FAIL quality-score "docs/QUALITY_SCORE.md must contain at least one initialized A-D score in a table."
  fi
}

check_guardrail() {
  local file="$REPO_ROOT/docs/RELIABILITY.md"
  local value

  [[ -f "$file" ]] || return
  value="$(field_value "$file" "Mechanical guardrail")"
  if is_configured_value "$value"; then
    report PASS mechanical-guardrail "docs/RELIABILITY.md records a mechanical guardrail."
  else
    report FAIL mechanical-guardrail "docs/RELIABILITY.md must configure '- Mechanical guardrail: ...'."
  fi
}

printf 'Harness check: %s\n' "$REPO_ROOT"
check_required_files
check_placeholders
check_baseline
check_commands
check_active_plan
check_markdown_links
check_legacy_issues
check_product_spec_index
check_quality_score
check_guardrail

if ((fail_count > 0)); then
  printf 'FAIL [summary] Harness configuration has %d failure(s).\n' "$fail_count"
  exit 1
fi

printf 'PASS [summary] Harness configuration is valid.\n'
