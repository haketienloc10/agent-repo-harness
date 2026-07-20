#!/usr/bin/env bash

set -euo pipefail

TEST_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
# shellcheck source=tests/lib.sh
source "$TEST_DIR/lib.sh"

new_temp_root

empty_repo="$TEMP_ROOT/empty"
new_git_repo "$empty_repo"
install_harness "$empty_repo" > "$TEMP_ROOT/empty.log"
assert_file "$empty_repo/AGENTS.md"
assert_file "$empty_repo/.harness/installation.json"
assert_not_exists "$empty_repo/index.md"
[[ -x "$empty_repo/scripts/harness-check.sh" ]] || fail "checker must remain executable"
assert_contains 'Summary: Created=' "$TEMP_ROOT/empty.log"
assert_contains 'Open docs/HARNESS_SETUP.md' "$TEMP_ROOT/empty.log"
assert_contains 'ready for user tasks only when the checker exits 0' "$TEMP_ROOT/empty.log"
pass "installer installs an empty Git repository and routes takeover to HARNESS_SETUP.md"

conflict_repo="$TEMP_ROOT/conflict"
new_git_repo "$conflict_repo"
printf 'project-owned agents\n' > "$conflict_repo/AGENTS.md"
expect_status 2 "$SOURCE_ROOT/install.sh" --target "$conflict_repo" > "$TEMP_ROOT/conflict.log"
assert_contains 'project-owned agents' "$conflict_repo/AGENTS.md"
assert_contains 'Conflicts: AGENTS.md' "$TEMP_ROOT/conflict.log"
assert_contains 'Review and resolve every Conflicts entry before takeover' "$TEMP_ROOT/conflict.log"
pass "installer preserves an existing AGENTS.md and blocks takeover on conflict"

dry_repo="$TEMP_ROOT/dry"
new_git_repo "$dry_repo"
install_harness "$dry_repo" --dry-run > "$TEMP_ROOT/dry.log"
assert_not_exists "$dry_repo/AGENTS.md"
assert_not_exists "$dry_repo/.harness"
assert_contains 'Mode: dry-run' "$TEMP_ROOT/dry.log"
pass "dry run does not change the target filesystem"

second_repo="$TEMP_ROOT/second"
new_git_repo "$second_repo"
install_harness "$second_repo" >/dev/null
metadata_before="$(sha256sum "$second_repo/.harness/installation.json")"
install_harness "$second_repo" > "$TEMP_ROOT/second.log"
metadata_after="$(sha256sum "$second_repo/.harness/installation.json")"
[[ "$metadata_before" == "$metadata_after" ]] || fail "second install changed installation metadata"
assert_contains 'Conflicts=0' "$TEMP_ROOT/second.log"
pass "second install preserves configured files and metadata"

overwrite_repo="$TEMP_ROOT/overwrite"
new_git_repo "$overwrite_repo"
printf 'recover me\n' > "$overwrite_repo/AGENTS.md"
install_harness "$overwrite_repo" --overwrite > "$TEMP_ROOT/overwrite.log"
backup_file="$(find "$overwrite_repo/.harness/backups" -type f -path '*/AGENTS.md' -print -quit)"
assert_file "$backup_file"
assert_contains 'recover me' "$backup_file"
assert_not_contains 'recover me' "$overwrite_repo/AGENTS.md"
pass "overwrite creates a recoverable backup"

expect_status 1 "$SOURCE_ROOT/install.sh" --target "$TEMP_ROOT/does-not-exist" > "$TEMP_ROOT/missing.log" 2>&1
assert_contains 'target does not exist' "$TEMP_ROOT/missing.log"
pass "installer rejects a missing target"

nongit_repo="$TEMP_ROOT/not-git"
mkdir -p -- "$nongit_repo"
expect_status 1 "$SOURCE_ROOT/install.sh" --target "$nongit_repo" > "$TEMP_ROOT/nongit.log" 2>&1
assert_contains 'target is not inside a Git repository' "$TEMP_ROOT/nongit.log"
pass "installer rejects a non-Git target"

github_source="$TEMP_ROOT/github-source"
mkdir -p -- "$github_source"
cp -a -- "$SOURCE_ROOT/." "$github_source/"
github_archive_dir="$TEMP_ROOT/haketienloc10/agent-repo-harness/archive"
mkdir -p -- "$github_archive_dir"
tar -czf "$github_archive_dir/main.tar.gz" -C "$TEMP_ROOT" "$(basename -- "$github_source")"
github_target="$TEMP_ROOT/github-target"
new_git_repo "$github_target"
GITHUB_ARCHIVE_BASE_URL="file://$TEMP_ROOT" \
  "$SOURCE_ROOT/install-from-github.sh" --target "$github_target" > "$TEMP_ROOT/github.log"
assert_file "$github_target/AGENTS.md"
assert_contains 'Downloading harness from haketienloc10/agent-repo-harness at ref main' "$TEMP_ROOT/github.log"
assert_contains 'Running installer' "$TEMP_ROOT/github.log"
pass "GitHub bootstrap installs without a local harness clone"
