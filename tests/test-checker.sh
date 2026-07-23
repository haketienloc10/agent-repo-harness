#!/usr/bin/env bash

set -euo pipefail

TEST_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
# shellcheck source=tests/lib.sh
source "$TEST_DIR/lib.sh"

new_temp_root

run_failure_case() {
  local name="$1"
  local expected="$2"
  local target="$TEMP_ROOT/$name"
  shift 2

  make_v1_repo "$target"
  "$@" "$target"
  expect_status 1 "$target/scripts/harness-check.sh" > "$TEMP_ROOT/$name.log"
  assert_contains "$expected" "$TEMP_ROOT/$name.log"
  pass "checker rejects $name"
}

remove_required() { rm -f -- "$1/docs/SECURITY.md"; }
add_placeholder() { printf '\n{{UNFILLED_VALUE}}\n' >> "$1/docs/DESIGN.md"; }
add_broken_link() { printf '\n[broken](missing.md)\n' >> "$1/docs/DESIGN.md"; }
break_revision() { sed -i 's/^- Git revision:.*/- Git revision: `not-a-revision`/' "$1/docs/PROJECT_BASELINE.md"; }
remove_evidence() { sed -i 's/^- Baseline evidence:.*/- Baseline evidence: /' "$1/docs/LEGACY_ISSUES.md"; }
run_failure_case missing-file 'docs/SECURITY.md is missing' remove_required
run_failure_case placeholder '{{UNFILLED_VALUE}}' add_placeholder
run_failure_case broken-link "points to missing relative target 'missing.md'" add_broken_link
run_failure_case missing-revision 'must contain a 7-64 character hexadecimal Git revision' break_revision
run_failure_case legacy-without-evidence "LEGACY-001 has no configured 'Baseline evidence'" remove_evidence
valid_legacy="$TEMP_ROOT/valid-legacy"
make_v1_repo "$valid_legacy"
expect_status 0 "$valid_legacy/scripts/harness-check.sh" > "$TEMP_ROOT/valid-legacy.log"
assert_contains 'BASELINE [legacy-issues] LEGACY-001' "$TEMP_ROOT/valid-legacy.log"
assert_contains 'PASS [active-plan] Active execution plan found:' "$TEMP_ROOT/valid-legacy.log"
assert_contains 'PASS [summary]' "$TEMP_ROOT/valid-legacy.log"
pass "valid legacy evidence does not fail the checker"

completed_plan="$TEMP_ROOT/completed-plan"
make_v1_repo "$completed_plan"
mv -- "$completed_plan/docs/exec-plans/active/verify-fixture.md" \
  "$completed_plan/docs/exec-plans/completed/verify-fixture.md"
expect_status 0 "$completed_plan/scripts/harness-check.sh" > "$TEMP_ROOT/completed-plan.log"
assert_file "$completed_plan/docs/exec-plans/completed/verify-fixture.md"
assert_contains '# Verify legacy fixture' \
  "$completed_plan/docs/exec-plans/completed/verify-fixture.md"
assert_contains 'No active execution plan; docs/exec-plans/active may be empty when no task is in progress' "$TEMP_ROOT/completed-plan.log"
assert_contains 'PASS [summary]' "$TEMP_ROOT/completed-plan.log"
pass "checker accepts and retains a completed plan while the active directory is empty"

complete="$TEMP_ROOT/complete"
make_v1_repo "$complete"
before="$(find "$complete" -type f -not -path '*/.git/*' -exec sha256sum {} + | sort | sha256sum)"
(
  cd "$complete/docs/exec-plans/active"
  expect_status 0 ../../../scripts/harness-check.sh
) > "$TEMP_ROOT/complete.log"
after="$(find "$complete" -type f -not -path '*/.git/*' -exec sha256sum {} + | sort | sha256sum)"
[[ "$before" == "$after" ]] || fail "checker modified the repository"
assert_contains 'PASS [summary]' "$TEMP_ROOT/complete.log"
pass "complete harness passes from a nested working directory without writes"
