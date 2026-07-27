#!/usr/bin/env bash

set -euo pipefail

TEST_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
# shellcheck source=tests/lib.sh
source "$TEST_DIR/lib.sh"

new_temp_root

template="$SOURCE_ROOT/workspace-template"

for relative_path in \
  AGENTS.md \
  identity.md \
  SYSTEM_MAP.md \
  repos.yaml \
  instructions/model-routing.md \
  .agents/skills/herdr/SKILL.md \
  .agents/skills/herdr/LICENSE.txt \
  .agents/skills/herdr/SOURCE.md \
  docs/WORKSPACE_SETUP.md \
  scripts/workspace-check.sh; do
  assert_file "$template/$relative_path"
done

assert_contains 'giữ vai trò **QiQi**' "$template/AGENTS.md"
assert_contains 'Không trực tiếp triển khai trong repository con' "$template/AGENTS.md"
assert_contains '`identity.md`' "$template/AGENTS.md"
assert_contains '`instructions/model-routing.md`' "$template/AGENTS.md"
assert_contains '`.agents/skills/herdr/SKILL.md`' "$template/AGENTS.md"
assert_contains 'HERDR_ENV=1' "$template/AGENTS.md"
assert_contains 'Tôi là **QiQi**' "$template/identity.md"
assert_contains 'Điểm mạnh' "$template/instructions/model-routing.md"
assert_contains 'Điểm yếu' "$template/instructions/model-routing.md"
assert_contains 'name: herdr' "$template/.agents/skills/herdr/SKILL.md"
assert_contains 'Apache License' "$template/.agents/skills/herdr/LICENSE.txt"
assert_contains 'a979916568b0225123711b1aa401d67102e3cf95' \
  "$template/.agents/skills/herdr/SOURCE.md"
assert_contains 'require_file "$workspace_root/identity.md"' \
  "$template/scripts/workspace-check.sh"
assert_contains 'require_file "$workspace_root/instructions/model-routing.md"' \
  "$template/scripts/workspace-check.sh"
assert_contains 'require_file "$workspace_root/.agents/skills/herdr/SKILL.md"' \
  "$template/scripts/workspace-check.sh"
pass "workspace template contains the QiQi contract, model routing, and vendored Herdr skill"

github_source="$TEMP_ROOT/github-source"
mkdir -p -- "$github_source"
cp -a -- "$SOURCE_ROOT/." "$github_source/"
github_archive_dir="$TEMP_ROOT/haketienloc10/agent-repo-harness/archive"
mkdir -p -- "$github_archive_dir"
tar -czf "$github_archive_dir/main.tar.gz" -C "$TEMP_ROOT" "$(basename -- "$github_source")"

workspace_target="$TEMP_ROOT/workspace-target"
new_git_repo "$workspace_target/module-a"
new_git_repo "$workspace_target/module-b"

GITHUB_ARCHIVE_BASE_URL="file://$TEMP_ROOT" \
  "$SOURCE_ROOT/install-from-github.sh" \
    --mode workspace \
    --target "$workspace_target" \
    > "$TEMP_ROOT/workspace.log"

for relative_path in \
  AGENTS.md \
  identity.md \
  SYSTEM_MAP.md \
  repos.yaml \
  instructions/model-routing.md \
  .agents/skills/herdr/SKILL.md \
  .agents/skills/herdr/LICENSE.txt \
  .agents/skills/herdr/SOURCE.md \
  docs/WORKSPACE_SETUP.md \
  scripts/workspace-check.sh; do
  assert_file "$workspace_target/$relative_path"
done

assert_contains 'Created: identity.md' "$TEMP_ROOT/workspace.log"
assert_contains 'Created: instructions/model-routing.md' "$TEMP_ROOT/workspace.log"
assert_contains 'Created: .agents/skills/herdr/SKILL.md' "$TEMP_ROOT/workspace.log"
assert_contains 'Local modifications: không có' \
  "$workspace_target/.agents/skills/herdr/SOURCE.md"
assert_contains 'Không trực tiếp triển khai trong repository con' \
  "$workspace_target/AGENTS.md"
assert_contains 'Không bắt đầu task sản phẩm trước khi hoàn tất các bước trên.' \
  "$TEMP_ROOT/workspace.log"
pass "workspace installer copies QiQi artifacts and the complete Herdr skill bundle"
