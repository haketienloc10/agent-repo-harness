#!/usr/bin/env bash

set -euo pipefail

TEST_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
# shellcheck source=tests/lib.sh
source "$TEST_DIR/lib.sh"

new_temp_root

empty_repo="$TEMP_ROOT/empty"
new_git_repo "$empty_repo"
install_harness "$empty_repo" > "$TEMP_ROOT/empty.log"
mapfile -t installed_files < <(
  find "$empty_repo" -path "$empty_repo/.git" -prune -o -type f -printf '%P\n' | sort
)
expected_files=(
  ".harness-required-files"
  ".harness/installation.json"
  "AGENTS.md"
  "ARCHITECTURE.md"
  "docs/HARNESS_SETUP.md"
  "docs/VERIFY.md"
  "scripts/harness-check.sh"
)
[[ "${installed_files[*]}" == "${expected_files[*]}" ]] || {
  printf 'Expected fresh-install files:\n%s\n' "${expected_files[*]}" >&2
  printf 'Actual fresh-install files:\n%s\n' "${installed_files[*]}" >&2
  fail "fresh install must contain exactly seven core files"
}
for excluded_path in \
  docs/QUALITY_SCORE.md docs/PRODUCT_SENSE.md docs/PLANS.md docs/DESIGN.md \
  docs/FRONTEND.md docs/TAKEOVER_BASELINE.md docs/product-specs \
  docs/generated docs/references docs/tasks/completed docs/exec-plans/completed; do
  assert_not_exists "$empty_repo/$excluded_path"
done
[[ -x "$empty_repo/scripts/harness-check.sh" ]] || fail "checker must remain executable"
assert_contains 'Mode: safe install (no overwrite)' "$TEMP_ROOT/empty.log"
assert_contains 'Summary: Created=' "$TEMP_ROOT/empty.log"
python3 - "$empty_repo/.harness/installation.json" "$(git -C "$SOURCE_ROOT" rev-parse HEAD)" <<'PY'
import datetime
import json
import sys

with open(sys.argv[1], encoding="utf-8") as stream:
    metadata = json.load(stream)

expected = {
    "schema": "harness/installation/v2",
    "source": "local",
    "ref": sys.argv[2],
    "harness_version": "1.0.0",
    "takeover_status": "pending",
    "baseline_revision": "",
    "takeover_completed_at": "",
    "blocker_reason": "",
}
for key, value in expected.items():
    if metadata.get(key) != value:
        raise SystemExit(f"{key}: expected {value!r}, got {metadata.get(key)!r}")
datetime.datetime.fromisoformat(metadata["installed_at"].replace("Z", "+00:00"))
PY
assert_contains 'Open docs/HARNESS_SETUP.md' "$TEMP_ROOT/empty.log"
assert_contains 'ready for user tasks only when the checker exits 0' "$TEMP_ROOT/empty.log"
assert_contains 'File này là router cho coding agent, không phải encyclopedia.' "$empty_repo/AGENTS.md"
assert_contains 'Trước code task không tầm thường' "$empty_repo/AGENTS.md"
assert_contains 'Đọc `ARCHITECTURE.md`' "$empty_repo/AGENTS.md"
assert_contains 'Đọc `docs/VERIFY.md`' "$empty_repo/AGENTS.md"
assert_contains 'Khi `takeover_status` là `complete`, không đọc' "$empty_repo/AGENTS.md"
assert_contains '`docs/tasks/completed/` | Chỉ khi cần lịch sử liên quan' "$empty_repo/AGENTS.md"
assert_not_contains 'docs/QUALITY_SCORE.md' "$empty_repo/AGENTS.md"
assert_not_contains 'docs/PLANS.md' "$empty_repo/AGENTS.md"
assert_not_contains 'docs/exec-plans/' "$empty_repo/AGENTS.md"
for plan_trigger in \
  'kéo dài qua nhiều phiên' \
  'chạm từ hai subsystem hoặc domain' \
  'có migration, backfill hoặc data transform' \
  'thay đổi public API hoặc external contract' \
  'có breaking change' \
  'chạm auth, secret hoặc sensitive data' \
  'cần rollout hoặc rollback phức tạp' \
  'cần chọn giữa nhiều phương án kiến trúc' \
  'có blocker hoặc dependency bên ngoài' \
  'người dùng yêu cầu plan' \
  'cần handoff cho người hoặc agent khác'; do
  assert_contains "$plan_trigger" "$empty_repo/AGENTS.md"
done
assert_contains 'Task nhỏ không có trigger thì không tạo plan.' "$empty_repo/AGENTS.md"
assert_contains 'không ghi log từng tool call.' "$empty_repo/AGENTS.md"
assert_contains '→ verification hoàn tất' "$empty_repo/AGENTS.md"
assert_contains '→ chắt lọc durable knowledge' "$empty_repo/AGENTS.md"
assert_contains '→ final summary' "$empty_repo/AGENTS.md"
assert_contains '→ chuyển sang docs/tasks/completed/' "$empty_repo/AGENTS.md"
assert_contains '→ giữ lâu dài' "$empty_repo/AGENTS.md"
assert_contains 'Không xóa completed plan.' "$empty_repo/AGENTS.md"
assert_contains 'Completed plan không thay thế spec, ADR,' "$empty_repo/AGENTS.md"
assert_contains 'File này mô tả kiến trúc thực đang tồn tại' "$empty_repo/ARCHITECTURE.md"
assert_contains 'không mô tả target' "$empty_repo/ARCHITECTURE.md"
assert_contains 'không ép chúng vào một' "$empty_repo/ARCHITECTURE.md"
assert_contains '## Dependency và data flow hiện tại' "$empty_repo/ARCHITECTURE.md"
assert_contains 'Chỉ liệt kê invariant có enforcement hoặc evidence cụ thể.' "$empty_repo/ARCHITECTURE.md"
assert_not_contains 'Types -> Config -> Repo -> Service -> Runtime -> UI' "$empty_repo/ARCHITECTURE.md"
assert_not_contains 'Các lớp thấp hơn không được phụ thuộc vào các lớp cao hơn.' "$empty_repo/ARCHITECTURE.md"
assert_contains '## Installation state machine' "$empty_repo/docs/HARNESS_SETUP.md"
assert_contains 'Khi bắt đầu takeover, tạo `docs/TAKEOVER_BASELINE.md`' "$empty_repo/docs/HARNESS_SETUP.md"
assert_contains 'Takeover chỉ complete khi `./scripts/harness-check.sh` trả exit `0`' "$empty_repo/docs/HARNESS_SETUP.md"
assert_contains 'Chỉ tạo optional artifact khi concern tồn tại' "$empty_repo/docs/HARNESS_SETUP.md"
assert_contains 'Không tạo file chỉ chứa' "$empty_repo/docs/HARNESS_SETUP.md"
assert_not_contains 'docs/QUALITY_SCORE.md' "$empty_repo/docs/HARNESS_SETUP.md"
assert_not_contains 'docs/PROJECT_BASELINE.md' "$empty_repo/docs/HARNESS_SETUP.md"
assert_not_contains 'docs/RELIABILITY.md' "$empty_repo/docs/HARNESS_SETUP.md"
expect_status 1 "$empty_repo/scripts/harness-check.sh" > "$TEMP_ROOT/empty-check.log"
assert_contains 'Takeover is pending; the repository is not ready for user tasks.' "$TEMP_ROOT/empty-check.log"
assert_not_contains 'PASS [summary] Harness configuration is valid.' "$TEMP_ROOT/empty-check.log"
pass "installer emits exactly seven v2 core files and leaves pending repository not ready"

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
sed -i \
  -e 's/"takeover_status": "pending"/"takeover_status": "blocked"/' \
  -e 's/"blocker_reason": ""/"blocker_reason": "Waiting for repository credentials."/' \
  "$second_repo/.harness/installation.json"
metadata_before="$(<"$second_repo/.harness/installation.json")"
install_harness "$second_repo" > "$TEMP_ROOT/second.log"
metadata_after="$(<"$second_repo/.harness/installation.json")"
[[ "$metadata_before" == "$metadata_after" ]] || fail "second install changed installation metadata"
assert_contains '"takeover_status": "blocked"' "$second_repo/.harness/installation.json"
assert_contains '"blocker_reason": "Waiting for repository credentials."' "$second_repo/.harness/installation.json"
assert_contains 'Skipped: .harness/installation.json (installation metadata preserved)' "$TEMP_ROOT/second.log"
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
assert_contains 'Mode: overwrite with backup' "$TEMP_ROOT/overwrite.log"
assert_contains 'Created: AGENTS.md (overwritten; backup:' "$TEMP_ROOT/overwrite.log"
pass "overwrite creates a recoverable backup"

upgrade_repo="$TEMP_ROOT/upgrade-v1"
new_git_repo "$upgrade_repo"
mkdir -p -- \
  "$upgrade_repo/.harness" \
  "$upgrade_repo/docs/exec-plans/active" \
  "$upgrade_repo/docs/product-specs" \
  "$upgrade_repo/docs/specs"
printf 'custom v1 agents\n' > "$upgrade_repo/AGENTS.md"
printf 'custom reliability evidence\n' > "$upgrade_repo/docs/RELIABILITY.md"
printf 'custom active plan\n' > "$upgrade_repo/docs/exec-plans/active/custom-plan.md"
printf 'custom product spec\n' > "$upgrade_repo/docs/product-specs/custom.md"
printf 'existing v2 product spec\n' > "$upgrade_repo/docs/specs/custom.md"
write_v2_metadata "$upgrade_repo" complete "abc123" "2026-07-17T00:00:00Z"
deprecated_before="$(
  sha256sum \
    "$upgrade_repo/docs/RELIABILITY.md" \
    "$upgrade_repo/docs/exec-plans/active/custom-plan.md" \
    "$upgrade_repo/docs/product-specs/custom.md" \
    "$upgrade_repo/docs/specs/custom.md"
)"
metadata_before="$(sha256sum "$upgrade_repo/.harness/installation.json")"
expect_status 2 "$SOURCE_ROOT/install.sh" --target "$upgrade_repo" --overwrite > "$TEMP_ROOT/upgrade-v1.log"
deprecated_after="$(
  sha256sum \
    "$upgrade_repo/docs/RELIABILITY.md" \
    "$upgrade_repo/docs/exec-plans/active/custom-plan.md" \
    "$upgrade_repo/docs/product-specs/custom.md" \
    "$upgrade_repo/docs/specs/custom.md"
)"
metadata_after="$(sha256sum "$upgrade_repo/.harness/installation.json")"
[[ "$deprecated_before" == "$deprecated_after" ]] || fail "overwrite changed a deprecated or archive artifact"
[[ "$metadata_before" == "$metadata_after" ]] || fail "overwrite changed complete installation metadata"
upgrade_backup="$(find "$upgrade_repo/.harness/backups" -type f -path '*/AGENTS.md' -print -quit)"
assert_file "$upgrade_backup"
assert_contains 'custom v1 agents' "$upgrade_backup"
assert_not_contains 'custom v1 agents' "$upgrade_repo/AGENTS.md"
assert_contains 'CONFLICT: docs/RELIABILITY.md -> docs/VERIFY.md' "$TEMP_ROOT/upgrade-v1.log"
assert_contains 'CONFLICT: docs/product-specs -> docs/specs' "$TEMP_ROOT/upgrade-v1.log"
assert_contains 'MIGRATE: docs/exec-plans/active -> docs/tasks/active' "$TEMP_ROOT/upgrade-v1.log"
assert_contains '"takeover_status": "complete"' "$upgrade_repo/.harness/installation.json"
pass "overwrite backs up core files while preserving customized v1 artifacts and complete metadata"

dry_upgrade="$TEMP_ROOT/dry-upgrade-v1"
new_git_repo "$dry_upgrade"
mkdir -p -- "$dry_upgrade/docs/design-docs" "$dry_upgrade/docs/exec-plans/completed"
printf 'custom decision\n' > "$dry_upgrade/docs/design-docs/custom.md"
printf 'custom completed plan\n' > "$dry_upgrade/docs/exec-plans/completed/custom.md"
dry_inventory_before="$(
  find "$dry_upgrade" -path "$dry_upgrade/.git" -prune -o -printf '%P|%y\n' | sort
)"
dry_checksums_before="$(
  find "$dry_upgrade" -path "$dry_upgrade/.git" -prune -o -type f -print0 |
    sort -z |
    xargs -0 -r sha256sum
)"
install_harness "$dry_upgrade" --dry-run > "$TEMP_ROOT/dry-upgrade-v1.log"
dry_inventory_after="$(
  find "$dry_upgrade" -path "$dry_upgrade/.git" -prune -o -printf '%P|%y\n' | sort
)"
dry_checksums_after="$(
  find "$dry_upgrade" -path "$dry_upgrade/.git" -prune -o -type f -print0 |
    sort -z |
    xargs -0 -r sha256sum
)"
[[ "$dry_inventory_before" == "$dry_inventory_after" ]] || fail "upgrade dry-run changed filesystem inventory"
[[ "$dry_checksums_before" == "$dry_checksums_after" ]] || fail "upgrade dry-run changed file content"
assert_contains 'MIGRATE: docs/design-docs -> docs/decisions' "$TEMP_ROOT/dry-upgrade-v1.log"
assert_contains 'MIGRATE: docs/exec-plans/completed -> docs/tasks/completed' "$TEMP_ROOT/dry-upgrade-v1.log"
pass "upgrade dry run creates, deletes, and renames nothing"

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
  "$SOURCE_ROOT/install-from-github.sh" --mode repository --target "$github_target" > "$TEMP_ROOT/github.log"
assert_file "$github_target/AGENTS.md"
assert_contains '"source": "github:haketienloc10/agent-repo-harness"' "$github_target/.harness/installation.json"
assert_contains '"ref": "main"' "$github_target/.harness/installation.json"
assert_contains 'Downloading harness from haketienloc10/agent-repo-harness at ref main' "$TEMP_ROOT/github.log"
assert_contains 'Running repository installer' "$TEMP_ROOT/github.log"
assert_contains 'docs/HARNESS_SETUP.md' "$TEMP_ROOT/github.log"
assert_contains '=== PROMPT CHO AGENT ===' "$TEMP_ROOT/github.log"
pass "GitHub bootstrap installs repository mode without a local harness clone"

workspace_target="$TEMP_ROOT/workspace-target"
new_git_repo "$workspace_target/module-a"
new_git_repo "$workspace_target/module-b"
printf 'module-owned source\n' > "$workspace_target/module-a/source.txt"
GITHUB_ARCHIVE_BASE_URL="file://$TEMP_ROOT" \
  "$SOURCE_ROOT/install-from-github.sh" --mode workspace --target "$workspace_target" > "$TEMP_ROOT/workspace.log"
assert_file "$workspace_target/AGENTS.md"
assert_file "$workspace_target/repos.yaml"
assert_file "$workspace_target/SYSTEM_MAP.md"
assert_file "$workspace_target/docs/WORKSPACE_SETUP.md"
[[ -x "$workspace_target/scripts/workspace-check.sh" ]] || fail "workspace checker must remain executable"
assert_not_exists "$workspace_target/.git"
assert_contains 'module-owned source' "$workspace_target/module-a/source.txt"
assert_contains 'Running workspace-template installer' "$TEMP_ROOT/workspace.log"
assert_contains 'docs/WORKSPACE_SETUP.md' "$TEMP_ROOT/workspace.log"
assert_contains './scripts/workspace-check.sh' "$TEMP_ROOT/workspace.log"
assert_contains '=== PROMPT CHO AGENT ===' "$TEMP_ROOT/workspace.log"
pass "GitHub bootstrap installs workspace mode without modifying child repositories"

workspace_conflict="$TEMP_ROOT/workspace-conflict"
new_git_repo "$workspace_conflict/module-a"
printf 'workspace-owned agents\n' > "$workspace_conflict/AGENTS.md"
expect_status 2 env GITHUB_ARCHIVE_BASE_URL="file://$TEMP_ROOT" \
  "$SOURCE_ROOT/install-from-github.sh" --mode workspace --target "$workspace_conflict" > "$TEMP_ROOT/workspace-conflict.log"
assert_contains 'workspace-owned agents' "$workspace_conflict/AGENTS.md"
assert_contains 'Conflicts: AGENTS.md' "$TEMP_ROOT/workspace-conflict.log"
assert_contains 'Cài đặt có Conflicts' "$TEMP_ROOT/workspace-conflict.log"
pass "workspace mode preserves conflicting root files and returns an actionable agent prompt"

workspace_dry="$TEMP_ROOT/workspace-dry"
new_git_repo "$workspace_dry/module-a"
GITHUB_ARCHIVE_BASE_URL="file://$TEMP_ROOT" \
  "$SOURCE_ROOT/install-from-github.sh" --mode workspace --target "$workspace_dry" --dry-run > "$TEMP_ROOT/workspace-dry.log"
assert_not_exists "$workspace_dry/AGENTS.md"
assert_not_exists "$workspace_dry/repos.yaml"
assert_contains 'Mode: workspace, dry-run' "$TEMP_ROOT/workspace-dry.log"
pass "workspace mode dry run does not change the target filesystem"

nested_repo_target="$TEMP_ROOT/nested-repo-target"
new_git_repo "$nested_repo_target"
new_git_repo "$nested_repo_target/child"
expect_status 1 env GITHUB_ARCHIVE_BASE_URL="file://$TEMP_ROOT" \
  "$SOURCE_ROOT/install-from-github.sh" --mode repository --target "$nested_repo_target" > "$TEMP_ROOT/nested-repo.log" 2>&1
assert_contains 'choose workspace mode' "$TEMP_ROOT/nested-repo.log"
pass "repository mode rejects a target containing nested Git repositories"
