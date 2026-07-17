#!/usr/bin/env bash

set -euo pipefail

TEST_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
# shellcheck source=tests/lib.sh
source "$TEST_DIR/lib.sh"

new_temp_root
fixture_repo="$TEMP_ROOT/legacy-project"
cp -a -- "$SOURCE_ROOT/examples/legacy-project" "$fixture_repo"
new_git_repo "$fixture_repo"
git -C "$fixture_repo" add .
git -C "$fixture_repo" commit -qm 'legacy baseline'
revision="$(git -C "$fixture_repo" rev-parse HEAD)"

expect_status 0 "$fixture_repo/project-checks/build.sh" > "$TEMP_ROOT/build.log"
expect_status 1 "$fixture_repo/project-checks/test.sh" > "$TEMP_ROOT/test.log" 2>&1
expect_status 1 "$fixture_repo/project-checks/lint.sh" > "$TEMP_ROOT/lint.log" 2>&1
assert_contains 'FAIL legacy greeting' "$TEMP_ROOT/test.log"
assert_contains 'LEGACY_STYLE' "$TEMP_ROOT/lint.log"

source_before="$(cd "$fixture_repo" && git ls-files -z | xargs -0 sha256sum | sort | sha256sum)"
install_harness "$fixture_repo" > "$TEMP_ROOT/install.log"
source_after="$(cd "$fixture_repo" && git ls-files -z | xargs -0 sha256sum | sort | sha256sum)"
[[ "$source_before" == "$source_after" ]] || fail "installer changed committed fixture source"
configure_harness "$fixture_repo" "$revision"

expect_status 0 "$fixture_repo/scripts/harness-check.sh" > "$TEMP_ROOT/check.log"
assert_contains "records revision $revision" "$TEMP_ROOT/check.log"
assert_contains "BASELINE [legacy-issues] LEGACY-001" "$TEMP_ROOT/check.log"
assert_contains 'PASS [summary]' "$TEMP_ROOT/check.log"
[[ "$(git -C "$fixture_repo" rev-parse HEAD)" == "$revision" ]] || fail "baseline revision moved"
git -C "$fixture_repo" diff --exit-code -- app.sh project-checks README.md

assert_contains 'Regression' "$fixture_repo/docs/HARNESS_SETUP.md"
assert_contains 'không chuyển thành legacy issue' "$fixture_repo/docs/HARNESS_SETUP.md"
assert_contains 'Nợ kỹ thuật' "$fixture_repo/docs/HARNESS_SETUP.md"
pass "end-to-end legacy takeover preserves source and accepts evidenced baseline failures"
