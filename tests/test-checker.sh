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

pending="$TEMP_ROOT/v2-pending"
make_v2_repo "$pending" pending
expect_status 1 "$pending/scripts/harness-check.sh" > "$TEMP_ROOT/v2-pending.log"
assert_contains 'WARN [takeover-status] Takeover is pending; the repository is not ready for user tasks.' "$TEMP_ROOT/v2-pending.log"
assert_contains 'WARN [summary] Harness takeover is pending and is not ready for user tasks.' "$TEMP_ROOT/v2-pending.log"
assert_not_contains 'PASS [summary]' "$TEMP_ROOT/v2-pending.log"
pass "v2 pending repository is not reported ready"

blocked_without_reason="$TEMP_ROOT/v2-blocked-without-reason"
make_v2_repo "$blocked_without_reason" blocked
expect_status 1 "$blocked_without_reason/scripts/harness-check.sh" > "$TEMP_ROOT/v2-blocked-without-reason.log"
assert_contains "FAIL [installation-metadata] takeover_status 'blocked' requires a specific blocker_reason." "$TEMP_ROOT/v2-blocked-without-reason.log"
pass "v2 blocked repository requires a specific reason"

blocked="$TEMP_ROOT/v2-blocked"
make_v2_repo "$blocked" blocked "" "" "Upstream credentials are unavailable."
expect_status 1 "$blocked/scripts/harness-check.sh" > "$TEMP_ROOT/v2-blocked.log"
assert_contains 'BLOCKED [takeover-status] Upstream credentials are unavailable.' "$TEMP_ROOT/v2-blocked.log"
assert_contains 'BLOCKED [summary] Harness takeover has 1 blocker(s).' "$TEMP_ROOT/v2-blocked.log"
pass "v2 blocked repository reports its blocker"

complete_without_baseline="$TEMP_ROOT/v2-complete-without-baseline"
make_v2_repo "$complete_without_baseline" complete "" "2026-07-23T10:00:00Z"
expect_status 1 "$complete_without_baseline/scripts/harness-check.sh" > "$TEMP_ROOT/v2-complete-without-baseline.log"
assert_contains "takeover_status 'complete' requires baseline_revision" "$TEMP_ROOT/v2-complete-without-baseline.log"
pass "v2 complete repository requires baseline metadata"

complete_mismatch="$TEMP_ROOT/v2-complete-baseline-mismatch"
make_v2_repo "$complete_mismatch" complete deadbeef "2026-07-23T10:00:00Z"
expect_status 1 "$complete_mismatch/scripts/harness-check.sh" > "$TEMP_ROOT/v2-complete-baseline-mismatch.log"
assert_contains "baseline_revision 'deadbeef' does not match" "$TEMP_ROOT/v2-complete-baseline-mismatch.log"
pass "v2 complete repository rejects baseline mismatch"

complete_without_timestamp="$TEMP_ROOT/v2-complete-without-timestamp"
make_configured_repo "$complete_without_timestamp"
complete_without_timestamp_revision="$(git -C "$complete_without_timestamp" rev-parse HEAD)"
write_v2_metadata "$complete_without_timestamp" complete "$complete_without_timestamp_revision"
expect_status 1 "$complete_without_timestamp/scripts/harness-check.sh" > "$TEMP_ROOT/v2-complete-without-timestamp.log"
assert_contains "takeover_status 'complete' requires takeover_completed_at as an RFC 3339 timestamp." "$TEMP_ROOT/v2-complete-without-timestamp.log"
pass "v2 complete repository requires completion timestamp"

complete_v2="$TEMP_ROOT/v2-complete"
make_configured_repo "$complete_v2"
complete_v2_revision="$(git -C "$complete_v2" rev-parse HEAD)"
cp -- "$complete_v2/docs/RELIABILITY.md" "$complete_v2/docs/VERIFY.md"
cp -- "$complete_v2/docs/PROJECT_BASELINE.md" "$complete_v2/docs/TAKEOVER_BASELINE.md"
write_v2_metadata "$complete_v2" complete "$complete_v2_revision" "2026-07-23T10:00:00Z"
expect_status 0 "$complete_v2/scripts/harness-check.sh" > "$TEMP_ROOT/v2-complete.log"
assert_contains 'PASS [commands] docs/VERIFY.md configures Bootstrap.' "$TEMP_ROOT/v2-complete.log"
assert_contains 'PASS [baseline-revision] docs/TAKEOVER_BASELINE.md records revision' "$TEMP_ROOT/v2-complete.log"
assert_contains 'PASS [takeover-status] Takeover is complete.' "$TEMP_ROOT/v2-complete.log"
assert_contains 'PASS [summary] Harness configuration is valid.' "$TEMP_ROOT/v2-complete.log"
pass "valid v2 complete repository passes with v2 path aliases"

malformed="$TEMP_ROOT/malformed-json"
make_v1_repo "$malformed"
printf '%s\n' '{"schema": "harness/installation/v2",' > "$malformed/.harness/installation.json"
expect_status 1 "$malformed/scripts/harness-check.sh" > "$TEMP_ROOT/malformed-json.log"
assert_contains 'FAIL [installation-metadata] .harness/installation.json is invalid JSON' "$TEMP_ROOT/malformed-json.log"
assert_contains 'repair or reinstall the metadata file.' "$TEMP_ROOT/malformed-json.log"
pass "malformed installation JSON fails with repair guidance"

unsupported_schema="$TEMP_ROOT/unsupported-schema"
make_v1_repo "$unsupported_schema"
printf '%s\n' '{"schema":"harness/installation/v3"}' > "$unsupported_schema/.harness/installation.json"
expect_status 1 "$unsupported_schema/scripts/harness-check.sh" > "$TEMP_ROOT/unsupported-schema.log"
assert_contains "FAIL [installation-metadata] Unsupported installation schema 'harness/installation/v3'" "$TEMP_ROOT/unsupported-schema.log"
pass "unsupported installation schema fails explicitly"

invalid_status="$TEMP_ROOT/v2-invalid-status"
make_v2_repo "$invalid_status" ready
expect_status 1 "$invalid_status/scripts/harness-check.sh" > "$TEMP_ROOT/v2-invalid-status.log"
assert_contains "FAIL [installation-metadata] Invalid takeover_status 'ready'" "$TEMP_ROOT/v2-invalid-status.log"
pass "v2 takeover status enum is validated"

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
