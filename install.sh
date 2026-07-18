#!/usr/bin/env bash

set -u
set -o pipefail

HARNESS_VERSION="1.0.0"
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
MANIFEST_PATH="$SCRIPT_DIR/.harness-required-files"
TEMPLATE_DIR="$SCRIPT_DIR/repo-template"

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
  metadata="$(printf '{\n  \"installed_at\": \"%s\",\n  \"harness_version\": \"%s\",\n  \"baseline_status\": \"pending\"\n}\n' "$installed_at" "$HARNESS_VERSION")"

  if find_unsafe_parent "$relative_path"; then
    record_conflict "$relative_path (unsafe parent path: $unsafe_parent)"
    return
  fi
  if [[ -e "$destination" || -L "$destination" ]]; then
    if [[ "$overwrite" != true ]]; then
      printf 'Skipped: %s (installation metadata preserved)\n' "$relative_path"
      ((skipped_count += 1))
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
    mkdir -p -- "$(dirname -- "$destination")" || fail "cannot create metadata directory."
    printf '%s\n' "$metadata" > "$destination" || fail "cannot write installation metadata."
    printf 'Created: %s (overwritten; backup: %s)\n' "$relative_path" "$backup_root/$relative_path"
    ((created_count += 1))
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

printf '\nSummary: Created=%d Skipped=%d Conflicts=%d\n' "$created_count" "$skipped_count" "$conflict_count"
if [[ "$backup_created" == true ]]; then
  printf 'Backups: %s\n' "$backup_root"
fi

printf '\nNext steps:\n'
if ((conflict_count > 0)); then
  printf '1. Review and resolve every Conflicts entry before takeover.\n'
  printf '2. Do not use --overwrite until each existing file and backup has been reviewed.\n'
  printf '3. After resolving conflicts, read docs/HARNESS_SETUP.md and follow every step in order.\n'
else
  printf '1. Open docs/HARNESS_SETUP.md in the target repository.\n'
  printf '2. Follow the takeover workflow in order; do not start user product tasks yet.\n'
  printf '3. Run ./scripts/harness-check.sh after the survey artifacts are complete.\n'
  printf '4. The repository is ready for user tasks only when the checker exits 0.\n'
fi

if ((conflict_count > 0)); then
  exit 2
fi
