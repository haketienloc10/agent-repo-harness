#!/usr/bin/env bash

set -euo pipefail

TEST_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
# shellcheck source=tests/lib.sh
source "$TEST_DIR/lib.sh"

new_temp_root

write_v1_metadata() {
  local target="$1"

  mkdir -p -- "$target/.harness"
  printf '%s\n' \
    '{' \
    '  "installed_at": "2026-07-17T00:00:00Z",' \
    '  "harness_version": "1.0.0",' \
    '  "baseline_status": "complete"' \
    '}' \
    > "$target/.harness/installation.json"
}

clean_v1="$TEMP_ROOT/clean-v1"
new_git_repo "$clean_v1"
write_v1_metadata "$clean_v1"
mkdir -p -- "$clean_v1/docs"
printf '# v1 reliability\n' > "$clean_v1/docs/RELIABILITY.md"
metadata_before="$(sha256sum "$clean_v1/.harness/installation.json")"
expect_status 2 "$SOURCE_ROOT/install.sh" --target "$clean_v1" > "$TEMP_ROOT/clean-v1.log"
metadata_after="$(sha256sum "$clean_v1/.harness/installation.json")"
[[ "$metadata_before" == "$metadata_after" ]] || fail "clean v1 metadata changed during upgrade inventory"
assert_file "$clean_v1/docs/VERIFY.md"
assert_file "$clean_v1/scripts/harness-check.sh"
assert_contains 'CONFLICT: docs/RELIABILITY.md -> docs/VERIFY.md' "$TEMP_ROOT/clean-v1.log"
assert_contains 'Skipped: .harness/installation.json (installation metadata preserved)' \
  "$TEMP_ROOT/clean-v1.log"
pass "clean v1 upgrade installs v2 core while preserving v1 metadata and reporting migration"

custom_v1="$TEMP_ROOT/custom-v1"
new_git_repo "$custom_v1"
write_v1_metadata "$custom_v1"
mkdir -p -- "$custom_v1/docs/design-docs" "$custom_v1/docs/product-specs"
printf 'repository-specific agents\n' > "$custom_v1/AGENTS.md"
printf 'custom auth decision\n' > "$custom_v1/docs/design-docs/auth.md"
printf 'custom sign-in behavior\n' > "$custom_v1/docs/product-specs/sign-in.md"
custom_before="$(
  sha256sum \
    "$custom_v1/AGENTS.md" \
    "$custom_v1/docs/design-docs/auth.md" \
    "$custom_v1/docs/product-specs/sign-in.md"
)"
expect_status 2 "$SOURCE_ROOT/install.sh" --target "$custom_v1" > "$TEMP_ROOT/custom-v1.log"
custom_after="$(
  sha256sum \
    "$custom_v1/AGENTS.md" \
    "$custom_v1/docs/design-docs/auth.md" \
    "$custom_v1/docs/product-specs/sign-in.md"
)"
[[ "$custom_before" == "$custom_after" ]] || fail "customized v1 content changed during safe upgrade"
assert_contains 'Conflicts: AGENTS.md' "$TEMP_ROOT/custom-v1.log"
assert_contains 'MIGRATE: docs/design-docs -> docs/decisions' "$TEMP_ROOT/custom-v1.log"
assert_contains 'MIGRATE: docs/product-specs -> docs/specs' "$TEMP_ROOT/custom-v1.log"
pass "customized v1 upgrade preserves repository-owned core and optional artifacts"

completed_v1="$TEMP_ROOT/completed-v1"
new_git_repo "$completed_v1"
write_v1_metadata "$completed_v1"
mkdir -p -- "$completed_v1/docs/exec-plans/completed"
printf 'completed alpha\n' > "$completed_v1/docs/exec-plans/completed/alpha.md"
printf 'completed beta\n' > "$completed_v1/docs/exec-plans/completed/beta.md"
completed_count_before="$(
  find "$completed_v1/docs/exec-plans/completed" -maxdepth 1 -type f -name '*.md' | wc -l
)"
completed_checksums_before="$(
  find "$completed_v1/docs/exec-plans/completed" -maxdepth 1 -type f -name '*.md' -print0 |
    sort -z |
    xargs -0 sha256sum
)"
install_harness "$completed_v1" > "$TEMP_ROOT/completed-v1.log"
completed_count_after="$(
  find "$completed_v1/docs/exec-plans/completed" -maxdepth 1 -type f -name '*.md' | wc -l
)"
completed_checksums_after="$(
  find "$completed_v1/docs/exec-plans/completed" -maxdepth 1 -type f -name '*.md' -print0 |
    sort -z |
    xargs -0 sha256sum
)"
[[ "$completed_count_before" -eq 2 && "$completed_count_after" -eq 2 ]] ||
  fail "completed v1 plan count was not preserved"
[[ "$completed_checksums_before" == "$completed_checksums_after" ]] ||
  fail "completed v1 plan checksums changed"
assert_contains 'MIGRATE: docs/exec-plans/completed -> docs/tasks/completed' \
  "$TEMP_ROOT/completed-v1.log"
pass "v1 completed plans retain count and byte-identical checksums"

path_conflict="$TEMP_ROOT/path-conflict"
cp -a -- "$completed_v1" "$path_conflict"
mkdir -p -- "$path_conflict/docs/tasks/completed"
printf 'different target alpha\n' > "$path_conflict/docs/tasks/completed/alpha.md"
source_before="$(sha256sum "$path_conflict/docs/exec-plans/completed/alpha.md")"
target_before="$(sha256sum "$path_conflict/docs/tasks/completed/alpha.md")"
expect_status 2 "$SOURCE_ROOT/install.sh" --target "$path_conflict" > "$TEMP_ROOT/path-conflict.log"
source_after="$(sha256sum "$path_conflict/docs/exec-plans/completed/alpha.md")"
target_after="$(sha256sum "$path_conflict/docs/tasks/completed/alpha.md")"
[[ "$source_before" == "$source_after" && "$target_before" == "$target_after" ]] ||
  fail "v1/v2 completed-plan conflict changed source or target"
assert_contains 'CONFLICT: docs/exec-plans/completed -> docs/tasks/completed (source and target both preserved)' \
  "$TEMP_ROOT/path-conflict.log"
pass "v1/v2 path conflict preserves both source and target"

reinstall_v2="$TEMP_ROOT/reinstall-v2"
new_git_repo "$reinstall_v2"
install_harness "$reinstall_v2" >/dev/null
sed -i \
  -e 's/"takeover_status": "pending"/"takeover_status": "blocked"/' \
  -e 's/"blocker_reason": ""/"blocker_reason": "Waiting for audit evidence."/' \
  "$reinstall_v2/.harness/installation.json"
reinstall_before="$(
  find "$reinstall_v2" -path "$reinstall_v2/.git" -prune -o -type f -print0 |
    sort -z |
    xargs -0 sha256sum
)"
install_harness "$reinstall_v2" > "$TEMP_ROOT/reinstall-v2.log"
reinstall_after="$(
  find "$reinstall_v2" -path "$reinstall_v2/.git" -prune -o -type f -print0 |
    sort -z |
    xargs -0 sha256sum
)"
[[ "$reinstall_before" == "$reinstall_after" ]] || fail "v2 reinstall changed managed content"
assert_contains 'Conflicts=0' "$TEMP_ROOT/reinstall-v2.log"
assert_contains '"blocker_reason": "Waiting for audit evidence."' \
  "$reinstall_v2/.harness/installation.json"
pass "v2 reinstall is idempotent and preserves takeover state"

dry_upgrade="$TEMP_ROOT/dry-upgrade"
new_git_repo "$dry_upgrade"
write_v1_metadata "$dry_upgrade"
mkdir -p -- "$dry_upgrade/docs/exec-plans/completed"
printf 'dry completed\n' > "$dry_upgrade/docs/exec-plans/completed/dry.md"
dry_inventory_before="$(
  find "$dry_upgrade" -path "$dry_upgrade/.git" -prune -o -printf '%P|%y\n' | sort
)"
dry_checksums_before="$(
  find "$dry_upgrade" -path "$dry_upgrade/.git" -prune -o -type f -print0 |
    sort -z |
    xargs -0 sha256sum
)"
install_harness "$dry_upgrade" --dry-run > "$TEMP_ROOT/dry-upgrade.log"
dry_inventory_after="$(
  find "$dry_upgrade" -path "$dry_upgrade/.git" -prune -o -printf '%P|%y\n' | sort
)"
dry_checksums_after="$(
  find "$dry_upgrade" -path "$dry_upgrade/.git" -prune -o -type f -print0 |
    sort -z |
    xargs -0 sha256sum
)"
[[ "$dry_inventory_before" == "$dry_inventory_after" ]] ||
  fail "upgrade dry-run changed filesystem inventory"
[[ "$dry_checksums_before" == "$dry_checksums_after" ]] ||
  fail "upgrade dry-run changed checksums"
assert_contains 'Mode: dry-run' "$TEMP_ROOT/dry-upgrade.log"
pass "v1 upgrade dry-run preserves inventory and checksums"

overwrite_v1="$TEMP_ROOT/overwrite-v1"
new_git_repo "$overwrite_v1"
write_v1_metadata "$overwrite_v1"
printf 'recover customized agents\n' > "$overwrite_v1/AGENTS.md"
install_harness "$overwrite_v1" --overwrite > "$TEMP_ROOT/overwrite-v1.log"
backup_file="$(find "$overwrite_v1/.harness/backups" -type f -path '*/AGENTS.md' -print -quit)"
assert_file "$backup_file"
assert_contains 'recover customized agents' "$backup_file"
assert_not_contains 'recover customized agents' "$overwrite_v1/AGENTS.md"
assert_contains 'Mode: overwrite with backup' "$TEMP_ROOT/overwrite-v1.log"
pass "v1 overwrite replaces core only after creating a recoverable backup"
