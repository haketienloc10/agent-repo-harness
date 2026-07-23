#!/usr/bin/env bash

set -u
set -o pipefail

HARNESS_VERSION="2.0.0"
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
TEMPLATE_DIR="$SCRIPT_DIR/repo-template"
MANIFEST_PATH="$TEMPLATE_DIR/.harness-required-files"
HARNESS_SOURCE="${HARNESS_SOURCE:-local}"
if [[ -z "${HARNESS_REF:-}" ]]; then
  HARNESS_REF="$(git -C "$SCRIPT_DIR" rev-parse HEAD 2>/dev/null || printf 'working-tree')"
fi

usage() {
  cat <<'USAGE'
Usage: ./install.sh --target /path/to/repo [--dry-run] [--overwrite]

Options:
  --target PATH  Existing Git repository root to receive the harness.
  --dry-run      Report actions without changing the filesystem.
  --overwrite    Back up and replace conflicting harness files.
  -h, --help     Show this help.
USAGE
}

fail() {
  printf 'Error: %s\n' "$1" >&2
  exit 1
}

target_input=""
dry_run=false
overwrite=false

while (($# > 0)); do
  case "$1" in
    --target)
      (($# >= 2)) || fail "--target requires a path."
      [[ -z "$target_input" ]] || fail "--target may only be specified once."
      target_input="$2"
      shift 2
      ;;
    --dry-run)
      dry_run=true
      shift
      ;;
    --overwrite)
      overwrite=true
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      fail "unknown argument: $1"
      ;;
  esac
done

[[ -n "$target_input" ]] || fail "--target is required."
[[ -d "$target_input" ]] || fail "target does not exist or is not a directory: $target_input"
[[ -f "$MANIFEST_PATH" ]] || fail "required-files manifest is missing: $MANIFEST_PATH"
[[ -d "$TEMPLATE_DIR" ]] || fail "template directory is missing: $TEMPLATE_DIR"

TARGET_DIR="$(cd -- "$target_input" && pwd -P)" || fail "cannot resolve target: $target_input"
git_root="$(git -C "$TARGET_DIR" rev-parse --show-toplevel 2>/dev/null)" || \
  fail "target is not inside a Git repository: $TARGET_DIR"
GIT_ROOT="$(cd -- "$git_root" && pwd -P)" || fail "cannot resolve Git repository root: $git_root"
[[ "$TARGET_DIR" == "$GIT_ROOT" ]] || fail "target must be the Git repository root: $GIT_ROOT"

if [[ "$dry_run" == true && "$overwrite" == true ]]; then
  printf 'Mode: dry-run with overwrite preview\n'
elif [[ "$dry_run" == true ]]; then
  printf 'Mode: dry-run\n'
elif [[ "$overwrite" == true ]]; then
  printf 'Mode: overwrite with backup\n'
else
  printf 'Mode: safe install (no overwrite)\n'
fi
printf 'Target: %s\n' "$TARGET_DIR"

installed_at="$(date -u +'%Y-%m-%dT%H:%M:%SZ')"
backup_root="$TARGET_DIR/.harness/backups/$(date -u +'%Y%m%dT%H%M%SZ')-$$"
backup_created=false
created_count=0
skipped_count=0
conflict_count=0
deprecated_count=0
unsafe_parent=""

validate_relative_path() {
  local path="$1"
  [[ -n "$path" && "$path" != /* && "$path" != ".." && "$path" != ../* && "$path" != */../* && "$path" != */.. ]]
}

find_unsafe_parent() {
  local relative_path="$1"
  local parent_path current component
  local -a components

  unsafe_parent=""
  parent_path="$(dirname -- "$relative_path")"
  [[ "$parent_path" != "." ]] || return 1
  current="$TARGET_DIR"
  IFS='/' read -r -a components <<< "$parent_path"
  for component in "${components[@]}"; do
    current="$current/$component"
    if [[ -L "$current" || ( -e "$current" && ! -d "$current" ) ]]; then
      unsafe_parent="$current"
      return 0
    fi
  done
  return 1
}

ensure_backup_root() {
  [[ "$backup_created" == false ]] || return 0
  [[ ! -L "$TARGET_DIR/.harness" && ( ! -e "$TARGET_DIR/.harness" || -d "$TARGET_DIR/.harness" ) ]] || \
    fail "cannot create backups under unsafe path: $TARGET_DIR/.harness"
  [[ ! -L "$TARGET_DIR/.harness/backups" && ( ! -e "$TARGET_DIR/.harness/backups" || -d "$TARGET_DIR/.harness/backups" ) ]] || \
    fail "cannot use unsafe backup path: $TARGET_DIR/.harness/backups"
  mkdir -p -- "$backup_root" || fail "cannot create backup directory: $backup_root"
  backup_created=true
}

backup_existing_file() {
  local relative_path="$1"
  local destination="$TARGET_DIR/$relative_path"
  local backup_path="$backup_root/$relative_path"
  ensure_backup_root
  mkdir -p -- "$(dirname -- "$backup_path")" || fail "cannot create backup parent for: $relative_path"
  cp -a -- "$destination" "$backup_path" || fail "cannot back up: $relative_path"
}

record_conflict() {
  printf 'Conflicts: %s\n' "$1"
  ((conflict_count += 1))
}

report_deprecated_artifact() {
  local action="$1"
  local source_path="$2"
  local target_path="${3:-}"

  [[ -e "$TARGET_DIR/$source_path" || -L "$TARGET_DIR/$source_path" ]] || return

  if [[ -n "$target_path" && ( -e "$TARGET_DIR/$target_path" || -L "$TARGET_DIR/$target_path" ) ]]; then
    printf 'CONFLICT: %s -> %s (source and target both preserved)\n' "$source_path" "$target_path"
    ((conflict_count += 1))
  elif [[ -n "$target_path" ]]; then
    printf '%s: %s -> %s\n' "$action" "$source_path" "$target_path"
  else
    printf '%s: %s\n' "$action" "$source_path"
  fi
  ((deprecated_count += 1))
}

report_deprecated_inventory() {
  printf '\nDeprecated harness v1 inventory:\n'

  report_deprecated_artifact MIGRATE "docs/RELIABILITY.md" "docs/VERIFY.md"
  report_deprecated_artifact MIGRATE "docs/PROJECT_BASELINE.md" "docs/TAKEOVER_BASELINE.md"
  report_deprecated_artifact MIGRATE "docs/product-specs" "docs/specs"
  report_deprecated_artifact MIGRATE "docs/design-docs" "docs/decisions"
  report_deprecated_artifact MIGRATE "docs/exec-plans/active" "docs/tasks/active"
  report_deprecated_artifact MIGRATE "docs/exec-plans/completed" "docs/tasks/completed"
  report_deprecated_artifact MIGRATE "docs/exec-plans/tech-debt-tracker.md" "docs/KNOWN_DEBT.md"

  report_deprecated_artifact REVIEW_AND_EXTRACT "docs/QUALITY_SCORE.md"
  report_deprecated_artifact REVIEW_AND_EXTRACT "docs/PRODUCT_SENSE.md"
  report_deprecated_artifact REVIEW_AND_EXTRACT "docs/DESIGN.md"
  report_deprecated_artifact REVIEW_AND_EXTRACT "docs/FRONTEND.md"
  report_deprecated_artifact REVIEW_AND_EXTRACT "docs/PLANS.md"

  report_deprecated_artifact REMOVE_SAMPLE "docs/product-specs/index.md"
  report_deprecated_artifact REMOVE_SAMPLE "docs/product-specs/new-user-onboarding.md"
  report_deprecated_artifact REMOVE_SAMPLE "docs/generated/db-schema.md"
  report_deprecated_artifact REMOVE_SAMPLE "docs/references/design-system-reference-llms.txt"
  report_deprecated_artifact REMOVE_SAMPLE "docs/references/nixpacks-llms.txt"
  report_deprecated_artifact REMOVE_SAMPLE "docs/references/uv-llms.txt"

  if ((deprecated_count == 0)); then
    printf 'None detected.\n'
  fi
}

copy_managed_file() {
  local relative_path="$1"
  local source_path="$2"
  local destination="$TARGET_DIR/$relative_path"

  if find_unsafe_parent "$relative_path"; then
    record_conflict "$relative_path (unsafe parent path: $unsafe_parent)"
    return
  fi

  if [[ -e "$destination" || -L "$destination" ]]; then
    if [[ -f "$destination" && ! -L "$destination" ]] && cmp -s -- "$source_path" "$destination"; then
      printf 'Skipped: %s (already current)\n' "$relative_path"
      ((skipped_count += 1))
      return
    fi
    if [[ "$overwrite" != true ]]; then
      record_conflict "$relative_path (existing file preserved)"
      return
    fi
    if [[ -d "$destination" && ! -L "$destination" ]]; then
      record_conflict "$relative_path (existing directory cannot be overwritten as a file)"
      return
    fi
    if [[ "$dry_run" == true ]]; then
      printf 'Created: %s (would overwrite; backup: %s)\n' "$relative_path" "$backup_root/$relative_path"
      ((created_count += 1))
      return
    fi
    backup_existing_file "$relative_path"
    rm -f -- "$destination" || fail "cannot replace: $relative_path"
    mkdir -p -- "$(dirname -- "$destination")" || fail "cannot create parent for: $relative_path"
    cp -p -- "$source_path" "$destination" || fail "cannot install: $relative_path"
    printf 'Created: %s (overwritten; backup: %s)\n' "$relative_path" "$backup_root/$relative_path"
    ((created_count += 1))
    return
  fi

  if [[ "$dry_run" == true ]]; then
    printf 'Created: %s (dry-run)\n' "$relative_path"
  else
    mkdir -p -- "$(dirname -- "$destination")" || fail "cannot create parent for: $relative_path"
    cp -p -- "$source_path" "$destination" || fail "cannot install: $relative_path"
    printf 'Created: %s\n' "$relative_path"
  fi
  ((created_count += 1))
}

install_metadata() {
  local relative_path=".harness/installation.json"
  local destination="$TARGET_DIR/$relative_path"
  local metadata
  metadata="$(printf '{\n  \"schema\": \"harness/installation/v2\",\n  \"source\": \"%s\",\n  \"ref\": \"%s\",\n  \"installed_at\": \"%s\",\n  \"harness_version\": \"%s\",\n  \"takeover_status\": \"pending\",\n  \"baseline_revision\": \"\",\n  \"takeover_completed_at\": \"\",\n  \"blocker_reason\": \"\",\n  \"baseline_status\": \"pending\"\n}\n' \
    "$HARNESS_SOURCE" "$HARNESS_REF" "$installed_at" "$HARNESS_VERSION")"

  if find_unsafe_parent "$relative_path"; then
    record_conflict "$relative_path (unsafe parent path: $unsafe_parent)"
    return
  fi
  if [[ -e "$destination" || -L "$destination" ]]; then
    if [[ -f "$destination" && ! -L "$destination" ]]; then
      printf 'Skipped: %s (installation metadata preserved)\n' "$relative_path"
      ((skipped_count += 1))
      return
    fi
    record_conflict "$relative_path (existing non-file path preserved)"
    return
  fi

  if [[ "$dry_run" == true ]]; then
    printf 'Created: %s (dry-run)\n' "$relative_path"
  else
    mkdir -p -- "$(dirname -- "$destination")" || fail "cannot create metadata directory."
    printf '%s\n' "$metadata" > "$destination" || fail "cannot write installation metadata."
    printf 'Created: %s\n' "$relative_path"
  fi
  ((created_count += 1))
}

while IFS= read -r relative_path || [[ -n "$relative_path" ]]; do
  [[ -z "$relative_path" || "$relative_path" == \#* ]] && continue
  validate_relative_path "$relative_path" || fail "unsafe path in manifest: $relative_path"
  case "$relative_path" in
    .harness/installation.json)
      install_metadata
      ;;
    .harness-required-files)
      copy_managed_file "$relative_path" "$MANIFEST_PATH"
      ;;
    *)
      source_path="$TEMPLATE_DIR/$relative_path"
      [[ -f "$source_path" ]] || fail "manifest entry is missing from template: $relative_path"
      copy_managed_file "$relative_path" "$source_path"
      ;;
  esac
done < "$MANIFEST_PATH"

report_deprecated_inventory

printf '\nSummary: Created=%d Skipped=%d Conflicts=%d\n' "$created_count" "$skipped_count" "$conflict_count"
if [[ "$backup_created" == true ]]; then
  printf 'Backups: %s\n' "$backup_root"
fi

takeover_status="pending"
metadata_path="$TARGET_DIR/.harness/installation.json"
if [[ -f "$metadata_path" ]]; then
  detected_status="$(sed -n 's/^[[:space:]]*"takeover_status"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "$metadata_path" | head -n 1)"
  if [[ -z "$detected_status" ]]; then
    detected_status="$(sed -n 's/^[[:space:]]*"baseline_status"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "$metadata_path" | head -n 1)"
  fi
  [[ -z "$detected_status" ]] || takeover_status="$detected_status"
fi

printf '\nNext steps:\n'
if ((conflict_count > 0)); then
  printf '1. Review and resolve every Conflicts entry before takeover; for CONFLICT inventory entries, source and target were both preserved.\n'
  printf '2. Compare and migrate content explicitly. Do not delete either path until its data is accounted for.\n'
elif ((deprecated_count > 0)); then
  printf '1. Review the deprecated inventory and handle each MIGRATE, REVIEW_AND_EXTRACT, and REMOVE_SAMPLE item explicitly.\n'
  printf '2. Extract durable knowledge before removing samples; do not delete or rename user data automatically.\n'
elif [[ "$takeover_status" == "complete" ]]; then
  printf '1. Takeover is already complete; do not restart the takeover workflow.\n'
  printf '2. Run ./scripts/harness-check.sh to verify the preserved repository state.\n'
elif [[ "$takeover_status" == "blocked" ]]; then
  printf '1. Takeover is blocked; read blocker_reason in .harness/installation.json.\n'
  printf '2. Resolve the recorded blocker, then continue docs/HARNESS_SETUP.md and run ./scripts/harness-check.sh.\n'
else
  printf '1. Open docs/HARNESS_SETUP.md in the target repository.\n'
  printf '2. Follow the takeover workflow in order; do not start user product tasks yet.\n'
  printf '3. Run ./scripts/harness-check.sh after the survey artifacts are complete.\n'
  printf '4. The repository is ready for user tasks only when the checker exits 0.\n'
fi

if ((conflict_count > 0)); then
  exit 2
fi
