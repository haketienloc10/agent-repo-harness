#!/usr/bin/env bash

set -euo pipefail

TEST_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
# shellcheck source=tests/lib.sh
source "$TEST_DIR/lib.sh"

new_temp_root

make_task_repo() {
  local target="$1"
  local revision

  make_configured_repo "$target"
  revision="$(git -C "$target" rev-parse HEAD)"
  cp -- "$target/docs/RELIABILITY.md" "$target/docs/VERIFY.md"
  cp -- "$target/docs/PROJECT_BASELINE.md" "$target/docs/TAKEOVER_BASELINE.md"
  write_v2_metadata "$target" complete "$revision" "2026-07-23T10:00:00Z"
  mkdir -p -- "$target/docs/tasks/active" "$target/docs/tasks/completed"
  printf '%s\n' \
    '# Cache invalidation task' \
    '## Goal' 'Automate greeting cache invalidation.' \
    '## Scope' '`src/cache` and its tests.' \
    '## Current state' \
    '- Phase: implementing' \
    '- Current result: The invalidation hook is implemented.' \
    '- Blocker: none' \
    '## Next action' 'Add the write-event test.' \
    '## Verification' 'Run `./project-checks/test.sh`.' \
    '## Durable knowledge to extract' 'Update `docs/VERIFY.md` if the verification command changes.' \
    > "$target/docs/tasks/active/cache.md"
  printf '%s\n' \
    '# JSON migration' \
    '## Final outcome' '`GET /greeting` now returns JSON.' \
    '## Verification evidence' '`./project-checks/test.sh` exited 0.' \
    '## Durable extraction' 'The contract remains in the source and completed plan.' \
    > "$target/docs/tasks/completed/json-migration.md"
}

no_friction="$TEMP_ROOT/no-friction"
make_task_repo "$no_friction"
expect_status 0 "$no_friction/scripts/harness-check.sh" > "$TEMP_ROOT/no-friction.log"
assert_contains 'PASS [active-plan] docs/tasks/active contains 1 plan(s)' "$TEMP_ROOT/no-friction.log"
assert_contains 'PASS [completed-plan] docs/tasks/completed contains 1 plan(s)' "$TEMP_ROOT/no-friction.log"
assert_not_contains '[active-friction]' "$TEMP_ROOT/no-friction.log"
assert_not_contains '[completed-friction]' "$TEMP_ROOT/no-friction.log"
pass "plans without friction remain valid and silent"

valid_friction="$TEMP_ROOT/valid-friction"
make_task_repo "$valid_friction"
printf '%s\n' \
  '## Friction' \
  '### `FR-001`: No narrow verification command' \
  '- Observed while: verifying' \
  '- Evidence: `./project-checks/test.sh` runs the complete suite.' \
  '- Impact: local feedback requires unrelated tests.' \
  '- Workaround: run the relevant shell assertion directly.' \
  '- Disposition: open' \
  >> "$valid_friction/docs/tasks/active/cache.md"
printf '%s\n' \
  '## Friction' \
  '### `FR-002`: Verification command was undocumented' \
  '- Observed while: verifying' \
  '- Evidence: the confirmed command existed only in CI configuration.' \
  '- Impact: the task initially used an incomplete local command.' \
  '- Workaround: use the CI command.' \
  '- Disposition: extracted-to-verify' \
  '- Extraction target: docs/VERIFY.md' \
  >> "$valid_friction/docs/tasks/completed/json-migration.md"
expect_status 0 "$valid_friction/scripts/harness-check.sh" > "$TEMP_ROOT/valid-friction.log"
assert_contains 'PASS [active-friction] docs/tasks/active/cache.md records 1 friction item(s)' \
  "$TEMP_ROOT/valid-friction.log"
assert_contains 'PASS [completed-friction] docs/tasks/completed/json-migration.md records 1 friction item(s)' \
  "$TEMP_ROOT/valid-friction.log"
pass "active open friction and completed routed friction pass"

empty_friction="$TEMP_ROOT/empty-friction"
make_task_repo "$empty_friction"
printf '%s\n' '## Friction' >> "$empty_friction/docs/tasks/active/cache.md"
expect_status 1 "$empty_friction/scripts/harness-check.sh" > "$TEMP_ROOT/empty-friction.log"
assert_contains 'has a Friction section without an FR-NNN item' "$TEMP_ROOT/empty-friction.log"
pass "empty friction sections fail instead of becoming placeholders"

missing_evidence="$TEMP_ROOT/missing-evidence"
make_task_repo "$missing_evidence"
printf '%s\n' \
  '## Friction' \
  '### `FR-001`: Validation is unclear' \
  '- Impact: the result cannot be demonstrated.' \
  '- Disposition: open' \
  >> "$missing_evidence/docs/tasks/active/cache.md"
expect_status 1 "$missing_evidence/scripts/harness-check.sh" > "$TEMP_ROOT/missing-evidence.log"
assert_contains "FR-001 has no configured 'Evidence'" "$TEMP_ROOT/missing-evidence.log"
pass "friction without evidence fails"

completed_open="$TEMP_ROOT/completed-open"
make_task_repo "$completed_open"
printf '%s\n' \
  '## Friction' \
  '### `FR-001`: Validation remains blocked' \
  '- Evidence: the required service is unavailable.' \
  '- Impact: the golden journey cannot be executed.' \
  '- Disposition: open' \
  >> "$completed_open/docs/tasks/completed/json-migration.md"
expect_status 1 "$completed_open/scripts/harness-check.sh" > "$TEMP_ROOT/completed-open.log"
assert_contains 'keeps FR-001 open in a completed plan' "$TEMP_ROOT/completed-open.log"
pass "completed plans reject open friction"

missing_target="$TEMP_ROOT/missing-target"
make_task_repo "$missing_target"
printf '%s\n' \
  '## Friction' \
  '### `FR-001`: Follow-up validation is required' \
  '- Evidence: the external sandbox is unavailable.' \
  '- Impact: integration behavior remains unverified.' \
  '- Disposition: follow-up-task' \
  >> "$missing_target/docs/tasks/completed/json-migration.md"
expect_status 1 "$missing_target/scripts/harness-check.sh" > "$TEMP_ROOT/missing-target.log"
assert_contains "FR-001 with disposition 'follow-up-task' requires an Extraction target" \
  "$TEMP_ROOT/missing-target.log"
pass "routed friction requires a concrete target"

invalid_disposition="$TEMP_ROOT/invalid-disposition"
make_task_repo "$invalid_disposition"
printf '%s\n' \
  '## Friction' \
  '### `FR-001`: Validation is expensive' \
  '- Evidence: the complete suite takes forty minutes.' \
  '- Impact: the feedback loop is delayed.' \
  '- Disposition: maybe-later' \
  >> "$invalid_disposition/docs/tasks/active/cache.md"
expect_status 1 "$invalid_disposition/scripts/harness-check.sh" > "$TEMP_ROOT/invalid-disposition.log"
assert_contains "FR-001 has invalid Disposition 'maybe-later'" "$TEMP_ROOT/invalid-disposition.log"
pass "friction disposition enum is enforced"
