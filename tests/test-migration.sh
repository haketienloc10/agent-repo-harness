#!/usr/bin/env bash

set -euo pipefail

TEST_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
# shellcheck source=tests/lib.sh
source "$TEST_DIR/lib.sh"

fixture="$TEST_DIR/fixtures/migration-v1-to-v2"
before="$fixture/before"
after="$fixture/after"
audit="$fixture/migration-audit.tsv"

expected_header=$'source path\tclassification\ttarget path\tcontent hash before\tcontent hash after\tdurable knowledge extracted to\tconflict status\treview status'
[[ "$(head -n 1 "$audit")" == "$expected_header" ]] ||
  fail "migration audit must contain all required fields"

audited_rows=0
while IFS=$'\t' read -r source_path classification target_path hash_before hash_after \
  durable_target conflict_status review_status; do
  [[ "$source_path" != "source path" ]] || continue
  [[ -n "$source_path" && -n "$classification" && -n "$target_path" ]] ||
    fail "migration audit contains an incomplete mapping"
  [[ -n "$hash_before" && -n "$hash_after" && -n "$durable_target" ]] ||
    fail "migration audit contains incomplete evidence for $source_path"
  [[ -n "$conflict_status" && -n "$review_status" ]] ||
    fail "migration audit contains incomplete review state for $source_path"
  assert_file "$before/$source_path"
  assert_file "$after/$target_path"
  [[ "$(sha256sum "$before/$source_path" | cut -d ' ' -f 1)" == "$hash_before" ]] ||
    fail "before checksum does not match audit for $source_path"
  [[ "$(sha256sum "$after/$target_path" | cut -d ' ' -f 1)" == "$hash_after" ]] ||
    fail "after checksum does not match audit for $source_path"
  ((audited_rows += 1))
done < "$audit"
[[ "$audited_rows" -eq 10 ]] || fail "expected 10 audited migration artifacts"
pass "migration audit records paths, classifications, hashes, extraction, conflicts, and review"

before_completed_count="$(find "$before/docs/exec-plans/completed" -maxdepth 1 -type f -name '*.md' | wc -l)"
after_completed_count="$(find "$after/docs/tasks/completed" -maxdepth 1 -type f -name '*.md' | wc -l)"
[[ "$before_completed_count" -eq "$after_completed_count" ]] ||
  fail "completed plan count changed during migration"
[[ "$before_completed_count" -eq 1 ]] || fail "fixture must contain a completed plan"
cmp -s \
  "$before/docs/exec-plans/completed/session-hardening.md" \
  "$after/docs/tasks/completed/session-hardening.md" ||
  fail "completed plan content must remain byte-identical"
assert_contains '## Decision' "$after/docs/tasks/completed/session-hardening.md"
assert_contains '## Verification evidence' "$after/docs/tasks/completed/session-hardening.md"
pass "completed plan count and checksum are preserved"

assert_contains '../../decisions/auth-boundary.md' "$after/docs/tasks/active/rotate-keys.md"
assert_not_contains '../../design-docs/auth-boundary.md' "$after/docs/tasks/active/rotate-keys.md"
assert_file "$after/docs/decisions/auth-boundary.md"
pass "migrated active plan link resolves to its v2 decision"

assert_not_contains '| C |' "$after/docs/KNOWN_DEBT.md"
assert_contains 'Refresh tokens appear in debug logs' "$after/docs/KNOWN_DEBT.md"
assert_contains 'src/auth/session.sh' "$after/docs/KNOWN_DEBT.md"
assert_contains 'docs/KNOWN_DEBT.md' "$audit"
assert_contains 'docs/SECURITY.md' "$audit"
pass "quality score is discarded while concrete gaps and durable knowledge have targets"

assert_contains 'Production key rotation requires two maintainers' "$after/docs/SECURITY.md"
assert_contains 'LEGACY-017' "$after/docs/LEGACY_ISSUES.md"
assert_file "$after/docs/references/sample-framework.txt"
assert_file "$after/docs/generated/db-schema.md"
assert_contains $'KEEP_OR_REMOVE_SAMPLE\tdocs/references/sample-framework.txt' "$audit"
assert_contains $'KEEP_OR_REMOVE_GENERATED\tdocs/generated/db-schema.md' "$audit"
pass "custom security, legacy, sample reference, and ungenerated schema remain reviewable"

assert_contains $'docs/RELIABILITY.md\tMIGRATE_EXTRACT\tdocs/VERIFY.md' "$audit"
assert_contains $'docs/VERIFY.md\tconflict\tpending' "$audit"
assert_file "$after/docs/RELIABILITY.md"
assert_file "$after/docs/VERIFY.md"
assert_contains 'This target v2 file existed before migration and was not overwritten.' \
  "$after/docs/VERIFY.md"
pass "source and target conflict preserves both files without overwrite"

assert_contains $'docs/unclassified/vendor-notes.dat\tUNCLASSIFIED' "$audit"
assert_file "$after/docs/unclassified/vendor-notes.dat"
cmp -s \
  "$before/docs/unclassified/vendor-notes.dat" \
  "$after/docs/unclassified/vendor-notes.dat" ||
  fail "unclassified artifact changed during migration"
pass "unclassified artifact is retained byte-identical"
