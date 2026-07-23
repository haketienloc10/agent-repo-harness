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
add_placeholder() { printf '\n{{UNFILLED_VALUE}}\n' >> "$1/ARCHITECTURE.md"; }
add_broken_link() { printf '\n[broken](missing.md)\n' >> "$1/ARCHITECTURE.md"; }
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
assert_not_contains 'FAIL [takeover-status]' "$TEMP_ROOT/v2-blocked.log"
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

optional_absent="$TEMP_ROOT/optional-absent"
make_v2_repo "$optional_absent" pending
optional_absent_revision="$(git -C "$optional_absent" rev-parse HEAD)"
write_v2_metadata "$optional_absent" complete "$optional_absent_revision" "2026-07-23T10:00:00Z"
sed -i '\|^docs/SECURITY.md$|d' "$optional_absent/.harness-required-files"
rm -f -- "$optional_absent/docs/SECURITY.md"
expect_status 0 "$optional_absent/scripts/harness-check.sh" > "$TEMP_ROOT/optional-absent.log"
assert_not_contains 'PASS [specs]' "$TEMP_ROOT/optional-absent.log"
assert_not_contains 'PASS [decisions]' "$TEMP_ROOT/optional-absent.log"
assert_not_contains 'PASS [ui]' "$TEMP_ROOT/optional-absent.log"
assert_not_contains 'PASS [security]' "$TEMP_ROOT/optional-absent.log"
assert_not_contains '[quality-score]' "$TEMP_ROOT/optional-absent.log"
pass "absent v2 specs decisions UI and security are silent and quality scores are ignored"

optional_contracts="$TEMP_ROOT/optional-contracts"
cp -a -- "$optional_absent" "$optional_contracts"
mkdir -p -- "$optional_contracts/docs/specs" "$optional_contracts/docs/decisions"
printf '%s\n' \
  '# Specs' '' '[Greeting API](greeting.md)' \
  > "$optional_contracts/docs/specs/index.md"
printf '%s\n' \
  '# Greeting API' \
  '## Scope' 'The `GET /greeting` endpoint.' \
  '## Observable behavior' 'Returns the configured greeting as JSON.' \
  '## Acceptance criteria' '`./project-checks/test.sh` verifies the response.' \
  '## Out of scope' 'Authentication behavior.' \
  '## Update trigger' 'Refresh when `GET /greeting` changes.' \
  > "$optional_contracts/docs/specs/greeting.md"
printf '%s\n' \
  '# Decisions' '' '[JSON response](0001-json-response.md)' \
  > "$optional_contracts/docs/decisions/index.md"
printf '%s\n' \
  '# Return JSON' \
  '## Status' 'Accepted' \
  '## Context' '`GET /greeting` has command-line and browser consumers.' \
  '## Decision' 'Return `application/json` from `src/greeting`.' \
  '## Consequences' 'Consumers parse a stable object shape.' \
  '## Verification' '`./project-checks/test.sh` checks the content type.' \
  > "$optional_contracts/docs/decisions/0001-json-response.md"
printf '%s\n' \
  '# UI contract' \
  '## Surfaces' '`web/greeting.html` renders the greeting.' \
  '## States' 'Loading, success, and HTTP error states are distinct.' \
  '## Interactions' 'The retry button calls `GET /greeting` once.' \
  '## Accessibility' 'Status changes use `role="status"`.' \
  '## Responsive rules' 'Below 40rem the action occupies one grid column.' \
  > "$optional_contracts/docs/UI.md"
printf '%s\n' \
  '# Security contract' \
  '## Assets' 'The greeting configuration is server-owned.' \
  '## Trust boundaries' '`GET /greeting` treats query input as untrusted.' \
  '## Threats' 'Unescaped values could create reflected HTML.' \
  '## Controls' '`src/greeting` JSON-encodes every response.' \
  '## Verification' '`./project-checks/test.sh` covers hostile input.' \
  > "$optional_contracts/docs/SECURITY.md"
expect_status 0 "$optional_contracts/scripts/harness-check.sh" > "$TEMP_ROOT/optional-contracts.log"
assert_contains 'PASS [specs]' "$TEMP_ROOT/optional-contracts.log"
assert_contains 'PASS [decisions]' "$TEMP_ROOT/optional-contracts.log"
assert_contains 'PASS [ui]' "$TEMP_ROOT/optional-contracts.log"
assert_contains 'PASS [security]' "$TEMP_ROOT/optional-contracts.log"
assert_contains 'BASELINE [legacy-issues] LEGACY-001 is documented with evidence at revision' \
  "$TEMP_ROOT/optional-contracts.log"
pass "valid v2 specs decisions UI and security contracts pass"

invalid_spec="$TEMP_ROOT/invalid-spec"
cp -a -- "$optional_contracts" "$invalid_spec"
printf '\n{{DEFINE_ACCEPTANCE}}\n' >> "$invalid_spec/docs/specs/greeting.md"
expect_status 1 "$invalid_spec/scripts/harness-check.sh" > "$TEMP_ROOT/invalid-spec.log"
assert_contains 'FAIL [specs] docs/specs/greeting.md:13:{{DEFINE_ACCEPTANCE}}' "$TEMP_ROOT/invalid-spec.log"
pass "optional spec placeholder fails with its path and line"

generic_ui="$TEMP_ROOT/generic-ui"
cp -a -- "$optional_contracts" "$generic_ui"
printf '\nFollow best practices and make it responsive.\n' >> "$generic_ui/docs/UI.md"
expect_status 0 "$generic_ui/scripts/harness-check.sh" > "$TEMP_ROOT/generic-ui.log"
assert_contains 'WARN [ui] docs/UI.md contains generic best-practice language' "$TEMP_ROOT/generic-ui.log"
assert_contains 'replace it with a repository-specific rule' "$TEMP_ROOT/generic-ui.log"
pass "generic UI guidance warns with an actionable correction"

optional_lifecycle="$TEMP_ROOT/optional-lifecycle"
cp -a -- "$optional_contracts" "$optional_lifecycle"
printf '%s\n' \
  '# Known debt' '' \
  '### `DEBT-001`: Cache invalidation remains manual' '' \
  '- Evidence: `src/cache` has no invalidation hook.' \
  '- Risk: stale greetings can remain visible for five minutes.' \
  '- Owner / tracking: platform team, issue `CACHE-12`.' \
  '- Review trigger: revisit when `src/cache` gains write events.' \
  '- Status: Open' \
  > "$optional_lifecycle/docs/KNOWN_DEBT.md"
mkdir -p -- "$optional_lifecycle/docs/tasks/active" \
  "$optional_lifecycle/docs/tasks/completed/history"
printf '%s\n' \
  '# Cache invalidation task' \
  '## Goal' 'Automate greeting cache invalidation.' \
  '## Scope' '`src/cache` and its tests.' \
  '## Current state' 'The invalidation hook is being implemented.' \
  '## Next action' 'Add the write-event test.' \
  '## Verification' 'Run `./project-checks/test.sh`.' \
  '## Durable knowledge to extract' 'Update `docs/decisions/0001-json-response.md` if the boundary changes.' \
  > "$optional_lifecycle/docs/tasks/active/cache.md"
printf '%s\n' \
  '# JSON migration' \
  '## Final outcome' '`GET /greeting` now returns JSON.' \
  '## Verification evidence' '`./project-checks/test.sh` exited 0.' \
  '## Durable extraction' 'The contract is in `docs/specs/greeting.md` and decision 0001.' \
  > "$optional_lifecycle/docs/tasks/completed/json-migration.md"
printf '{{ARCHIVE_ATTACHMENT_IS_NOT_A_PLAN}}\n' \
  > "$optional_lifecycle/docs/tasks/completed/history/attachment.md"
expect_status 0 "$optional_lifecycle/scripts/harness-check.sh" > "$TEMP_ROOT/optional-lifecycle.log"
assert_contains 'PASS [known-debt] DEBT-001' "$TEMP_ROOT/optional-lifecycle.log"
assert_contains 'PASS [active-plan] docs/tasks/active contains 1 plan(s)' "$TEMP_ROOT/optional-lifecycle.log"
assert_contains 'PASS [completed-plan] docs/tasks/completed contains 1 plan(s)' "$TEMP_ROOT/optional-lifecycle.log"
assert_not_contains 'ARCHIVE_ATTACHMENT_IS_NOT_A_PLAN' "$TEMP_ROOT/optional-lifecycle.log"
pass "valid debt and task lifecycle pass without traversing nested completed history"

invalid_lifecycle="$TEMP_ROOT/invalid-lifecycle"
cp -a -- "$optional_lifecycle" "$invalid_lifecycle"
sed -i 's/^- Status: Accepted$/- Status: Resolved/' "$invalid_lifecycle/docs/LEGACY_ISSUES.md"
sed -i 's/^- Status: Open$/- Status: Resolved/' "$invalid_lifecycle/docs/KNOWN_DEBT.md"
sed -i '/^## Next action$/,+1d' "$invalid_lifecycle/docs/tasks/active/cache.md"
expect_status 1 "$invalid_lifecycle/scripts/harness-check.sh" > "$TEMP_ROOT/invalid-lifecycle.log"
assert_contains 'keeps resolved LEGACY-001 as open state' "$TEMP_ROOT/invalid-lifecycle.log"
assert_contains 'keeps resolved DEBT-001 as open debt' "$TEMP_ROOT/invalid-lifecycle.log"
assert_contains "docs/tasks/active/cache.md:1 must contain a 'Next action' heading" "$TEMP_ROOT/invalid-lifecycle.log"
pass "resolved state and incomplete active plans fail with actionable locations"

optional_sources="$TEMP_ROOT/optional-sources"
cp -a -- "$optional_contracts" "$optional_sources"
mkdir -p -- "$optional_sources/docs/generated" "$optional_sources/docs/references"
printf '%s\n' \
  '# Generated greeting schema' '' \
  '- Source: `src/greeting/schema.json`' \
  '- Generator command: `./scripts/generate-schema.sh`' \
  '- Generator version: `schema-tool 2.1.0`' \
  '- Applies to: `GET /greeting` response consumers' \
  '- Refresh trigger: regenerate when `src/greeting/schema.json` changes' \
  > "$optional_sources/docs/generated/greeting-schema.md"
printf '%s\n' \
  '# HTTP semantics reference' '' \
  '- Source: https://www.rfc-editor.org/rfc/rfc9110' \
  '- Retrieved at: 2026-07-23' \
  '- Applies to: status handling in `src/greeting`' \
  '- Refresh trigger: refresh when the HTTP dependency changes major version' \
  > "$optional_sources/docs/references/http-semantics.md"
expect_status 0 "$optional_sources/scripts/harness-check.sh" > "$TEMP_ROOT/optional-sources.log"
assert_contains 'PASS [generated] docs/generated contains 1 traceable artifact(s)' "$TEMP_ROOT/optional-sources.log"
assert_contains 'PASS [references] docs/references contains 1 traceable artifact(s)' "$TEMP_ROOT/optional-sources.log"
pass "generated artifacts and references pass with source and refresh metadata"

invalid_sources="$TEMP_ROOT/invalid-sources"
cp -a -- "$optional_sources" "$invalid_sources"
sed -i '/^- Applies to:/d' "$invalid_sources/docs/generated/greeting-schema.md"
printf '\n{{REFERENCE_VERSION}}\n' >> "$invalid_sources/docs/references/http-semantics.md"
expect_status 1 "$invalid_sources/scripts/harness-check.sh" > "$TEMP_ROOT/invalid-sources.log"
assert_contains "docs/generated/greeting-schema.md:1 has no configured 'Applies to' metadata" "$TEMP_ROOT/invalid-sources.log"
assert_contains 'FAIL [references] docs/references/http-semantics.md:8:{{REFERENCE_VERSION}}' "$TEMP_ROOT/invalid-sources.log"
pass "untraceable generated and reference artifacts fail with actionable locations"

new_regression="$TEMP_ROOT/new-regression-as-legacy"
cp -a -- "$optional_contracts" "$new_regression"
sed -i 's/^- Baseline revision:.*/- Baseline revision: `deadbeef`/' \
  "$new_regression/docs/LEGACY_ISSUES.md"
expect_status 1 "$new_regression/scripts/harness-check.sh" > "$TEMP_ROOT/new-regression.log"
assert_contains "LEGACY-001 references baseline revision 'deadbeef', expected" \
  "$TEMP_ROOT/new-regression.log"
assert_contains 'Không đổi regression mới thành legacy issue hoặc debt' \
  "$SOURCE_ROOT/repo-template/AGENTS.md"
assert_contains 'Không đổi regression thành legacy issue hoặc debt' \
  "$SOURCE_ROOT/repo-template/docs/HARNESS_SETUP.md"
pass "a failure from a newer revision cannot be classified as baseline legacy"

unknown_observation="$TEMP_ROOT/unknown-observation"
cp -a -- "$optional_contracts" "$unknown_observation"
mkdir -p -- "$unknown_observation/docs/tasks/active"
printf '%s\n' \
  '# Investigate intermittent greeting failure' \
  '## Goal' 'Determine the failure origin without classifying it as legacy or debt.' \
  '## Scope' '`GET /greeting` observation and reproduction evidence.' \
  '## Current state' 'Observation: origin is unknown and no baseline reproduction exists.' \
  '## Next action' 'Reproduce at the takeover revision and current revision.' \
  '## Verification' 'Compare `./project-checks/test.sh` output at both revisions.' \
  '## Durable knowledge to extract' 'Route confirmed behavior to specs or confirmed baseline failure to legacy.' \
  > "$unknown_observation/docs/tasks/active/investigate-greeting.md"
expect_status 0 "$unknown_observation/scripts/harness-check.sh" > "$TEMP_ROOT/unknown-observation.log"
assert_contains 'PASS [active-plan] docs/tasks/active contains 1 plan(s)' \
  "$TEMP_ROOT/unknown-observation.log"
pass "unknown failure origin remains an observation in an active plan"

resolved_legacy_removed="$TEMP_ROOT/resolved-legacy-removed"
cp -a -- "$optional_contracts" "$resolved_legacy_removed"
sed -i '\|^docs/LEGACY_ISSUES.md$|d' "$resolved_legacy_removed/.harness-required-files"
rm -f -- "$resolved_legacy_removed/docs/LEGACY_ISSUES.md"
expect_status 0 "$resolved_legacy_removed/scripts/harness-check.sh" \
  > "$TEMP_ROOT/resolved-legacy-removed.log"
assert_not_contains '[legacy-issues]' "$TEMP_ROOT/resolved-legacy-removed.log"
pass "resolved legacy need not remain in optional state"

assert_not_contains 'check_quality_score' "$SOURCE_ROOT/repo-template/scripts/harness-check.sh"
assert_not_contains '[quality-score]' "$TEMP_ROOT/optional-contracts.log"
pass "v2 checker has no quality-score validator"

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
mkdir -p -- "$completed_plan/docs/exec-plans/completed"
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
