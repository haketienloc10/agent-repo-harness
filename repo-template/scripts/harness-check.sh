#!/usr/bin/env bash

set -u
set -o pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
REPO_ROOT="$(cd -- "$SCRIPT_DIR/.." && pwd -P)"
MANIFEST_PATH="$REPO_ROOT/.harness-required-files"
fail_count=0
blocked_count=0
pending_count=0
installation_schema="v1"
takeover_status=""
baseline_revision_metadata=""
takeover_completed_at=""
blocker_reason=""

# Reporting

record_failure() {
  ((fail_count += 1))
}

record_blocker() {
  ((blocked_count += 1))
}

report() {
  local status="$1"
  local check="$2"
  local message="$3"

  printf '%s [%s] %s\n' "$status" "$check" "$message"
  if [[ "$status" == "FAIL" ]]; then
    record_failure
  elif [[ "$status" == "BLOCKED" ]]; then
    record_blocker
  fi
}

report_summary() {
  if ((fail_count > 0)); then
    printf 'FAIL [summary] Harness configuration has %d failure(s).\n' "$fail_count"
    return 1
  fi

  if ((blocked_count > 0)); then
    printf 'BLOCKED [summary] Harness takeover has %d blocker(s).\n' "$blocked_count"
    return 1
  fi

  if ((pending_count > 0)); then
    printf 'WARN [summary] Harness takeover is pending and is not ready for user tasks.\n'
    return 1
  fi

  printf 'PASS [summary] Harness configuration is valid.\n'
}

# Metadata parsing

parse_installation_metadata() {
  local file="$REPO_ROOT/.harness/installation.json"
  local parser=""
  local output
  local -a values=()

  [[ -f "$file" ]] || return

  if command -v python3 >/dev/null 2>&1; then
    parser="python3"
    output="$(python3 - "$file" <<'PY' 2>&1
import json
import sys

try:
    with open(sys.argv[1], encoding="utf-8") as stream:
        data = json.load(stream)
    if not isinstance(data, dict):
        raise ValueError("top-level JSON value must be an object")
    keys = ("schema", "takeover_status", "baseline_revision", "takeover_completed_at", "blocker_reason")
    values = []
    for key in keys:
        value = data.get(key, "")
        if not isinstance(value, str):
            raise ValueError(f"{key} must be a string")
        if "\n" in value or "\r" in value:
            raise ValueError(f"{key} must not contain a newline")
        values.append(value)
    print("\n".join(values))
except (OSError, UnicodeError, json.JSONDecodeError, ValueError) as error:
    print(error, file=sys.stderr)
    sys.exit(1)
PY
)" || {
      report FAIL installation-metadata ".harness/installation.json is invalid JSON or has invalid fields ($parser: $output); repair or reinstall the metadata file."
      return
    }
  elif command -v ruby >/dev/null 2>&1; then
    parser="ruby"
    output="$(ruby -rjson -e '
      data = JSON.parse(File.read(ARGV[0]))
      raise "top-level JSON value must be an object" unless data.is_a?(Hash)
      keys = %w[schema takeover_status baseline_revision takeover_completed_at blocker_reason]
      puts keys.map { |key|
        value = data.fetch(key, "")
        raise "#{key} must be a string" unless value.is_a?(String)
        raise "#{key} must not contain a newline" if value.match?(/[\r\n]/)
        value
      }
    ' "$file" 2>&1)" || {
      report FAIL installation-metadata ".harness/installation.json is invalid JSON or has invalid fields ($parser: $output); repair or reinstall the metadata file."
      return
    }
  else
    report FAIL installation-metadata "Cannot parse .harness/installation.json safely; install python3 or ruby, then rerun the checker."
    return
  fi

  mapfile -t values <<< "$output"
  while ((${#values[@]} < 5)); do values+=(""); done
  if [[ -z "${values[0]}" ]]; then
    installation_schema="v1"
    return
  fi
  if [[ "${values[0]}" != "harness/installation/v2" ]]; then
    report FAIL installation-metadata "Unsupported installation schema '${values[0]}'; expected harness/installation/v2 or legacy v1 metadata without schema."
    installation_schema="invalid"
    return
  fi

  installation_schema="v2"
  takeover_status="${values[1]}"
  baseline_revision_metadata="${values[2]}"
  takeover_completed_at="${values[3]}"
  blocker_reason="${values[4]}"
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

# Path resolution

resolve_alias_path() {
  local v1_path="$1"
  local v2_path="$2"

  if [[ "$installation_schema" == "v2" ]]; then
    if [[ -f "$REPO_ROOT/$v2_path" ]]; then
      printf '%s' "$v2_path"
    else
      printf '%s' "$v1_path"
    fi
  elif [[ -f "$REPO_ROOT/$v1_path" ]]; then
    printf '%s' "$v1_path"
  else
    printf '%s' "$v2_path"
  fi
}

resolve_manifest_path() {
  case "$1" in
    docs/RELIABILITY.md|docs/VERIFY.md)
      resolve_alias_path docs/RELIABILITY.md docs/VERIFY.md
      ;;
    docs/PROJECT_BASELINE.md|docs/TAKEOVER_BASELINE.md)
      resolve_alias_path docs/PROJECT_BASELINE.md docs/TAKEOVER_BASELINE.md
      ;;
    *)
      printf '%s' "$1"
      ;;
  esac
}

emit_harness_files() {
  local path resolved_path
  local active_dir="$REPO_ROOT/docs/exec-plans/active"

  if [[ -f "$MANIFEST_PATH" ]]; then
    while IFS= read -r path || [[ -n "$path" ]]; do
      [[ -z "$path" || "$path" == \#* ]] && continue
      resolved_path="$(resolve_manifest_path "$path")"
      [[ -f "$REPO_ROOT/$resolved_path" ]] || continue
      printf '%s\0' "$REPO_ROOT/$resolved_path"
    done < "$MANIFEST_PATH"
  fi

  if [[ -d "$active_dir" ]]; then
    find "$active_dir" -maxdepth 1 -type f -name '*.md' ! -name 'index.md' -print0
  fi
}

check_required_files() {
  local path resolved_path
  local missing=0

  if [[ ! -f "$MANIFEST_PATH" ]]; then
    report FAIL required-files ".harness-required-files is missing; required files cannot be checked."
    return
  fi

  while IFS= read -r path || [[ -n "$path" ]]; do
    [[ -z "$path" || "$path" == \#* ]] && continue
    resolved_path="$(resolve_manifest_path "$path")"
    if [[ ! -f "$REPO_ROOT/$resolved_path" ]]; then
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
  local relative_path
  local file
  local date_value
  local revision_value

  relative_path="$(resolve_alias_path docs/PROJECT_BASELINE.md docs/TAKEOVER_BASELINE.md)"
  file="$REPO_ROOT/$relative_path"
  [[ -f "$file" ]] || return
  date_value="$(field_value "$file" "Ngày baseline")"
  revision_value="$(field_value "$file" "Git revision")"

  if [[ "$date_value" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
    report PASS baseline-date "$relative_path records baseline date $date_value."
  else
    report FAIL baseline-date "$relative_path must contain '- Ngày baseline: YYYY-MM-DD'."
  fi

  if [[ "$revision_value" =~ ^[0-9a-fA-F]{7,64}$ ]]; then
    report PASS baseline-revision "$relative_path records revision $revision_value."
  else
    report FAIL baseline-revision "$relative_path must contain a 7-64 character hexadecimal Git revision."
  fi
}

check_commands() {
  local relative_path
  local file
  local label
  local value
  local invalid=0

  relative_path="$(resolve_alias_path docs/RELIABILITY.md docs/VERIFY.md)"
  file="$REPO_ROOT/$relative_path"
  [[ -f "$file" ]] || return
  for label in "Bootstrap" "Xác minh" "Khởi động app hoặc service"; do
    value="$(field_value "$file" "$label")"
    if is_configured_value "$value"; then
      report PASS commands "$relative_path configures $label."
    else
      report FAIL commands "$relative_path has no configured value for '$label'."
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
    report PASS active-plan "No active execution plan; docs/exec-plans/active may be empty when no task is in progress."
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
  local baseline_file
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

  baseline_file="$REPO_ROOT/$(resolve_alias_path docs/PROJECT_BASELINE.md docs/TAKEOVER_BASELINE.md)"
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
  local relative_path
  local file
  local value

  relative_path="$(resolve_alias_path docs/RELIABILITY.md docs/VERIFY.md)"
  file="$REPO_ROOT/$relative_path"
  [[ -f "$file" ]] || return
  value="$(field_value "$file" "Mechanical guardrail")"
  if is_configured_value "$value"; then
    report PASS mechanical-guardrail "$relative_path records a mechanical guardrail."
  else
    report FAIL mechanical-guardrail "$relative_path must configure '- Mechanical guardrail: ...'."
  fi
}

# Installation state validation

check_installation_state() {
  local baseline_path
  local baseline_revision_file
  local failures_before="$fail_count"

  [[ "$installation_schema" == "v2" ]] || return
  case "$takeover_status" in
    pending)
      report WARN takeover-status "Takeover is pending; the repository is not ready for user tasks."
      ((pending_count += 1))
      ;;
    blocked)
      if is_configured_value "$blocker_reason"; then
        report BLOCKED takeover-status "$blocker_reason"
      else
        report FAIL installation-metadata "takeover_status 'blocked' requires a specific blocker_reason."
      fi
      ;;
    complete)
      baseline_path="$(resolve_alias_path docs/PROJECT_BASELINE.md docs/TAKEOVER_BASELINE.md)"
      if [[ ! "$baseline_revision_metadata" =~ ^[0-9a-fA-F]{7,64}$ ]]; then
        report FAIL installation-metadata "takeover_status 'complete' requires baseline_revision as a 7-64 character hexadecimal Git revision."
      elif [[ ! -f "$REPO_ROOT/$baseline_path" ]]; then
        report FAIL installation-metadata "takeover_status 'complete' requires docs/TAKEOVER_BASELINE.md or docs/PROJECT_BASELINE.md."
      else
        baseline_revision_file="$(field_value "$REPO_ROOT/$baseline_path" "Git revision")"
        if [[ "$baseline_revision_metadata" != "$baseline_revision_file" ]]; then
          report FAIL installation-metadata "baseline_revision '$baseline_revision_metadata' does not match '$baseline_revision_file' in $baseline_path."
        fi
      fi
      if [[ ! "$takeover_completed_at" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}(\.[0-9]+)?(Z|[+-][0-9]{2}:[0-9]{2})$ ]]; then
        report FAIL installation-metadata "takeover_status 'complete' requires takeover_completed_at as an RFC 3339 timestamp."
      fi
      if ((fail_count == failures_before)); then
        report PASS takeover-status "Takeover is complete."
      fi
      ;;
    *)
      report FAIL installation-metadata "Invalid takeover_status '$takeover_status'; expected pending, blocked, or complete."
      ;;
  esac
}

printf 'Harness check: %s\n' "$REPO_ROOT"
parse_installation_metadata
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
check_installation_state

report_summary
