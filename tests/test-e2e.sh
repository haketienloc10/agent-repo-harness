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
assert_contains 'Open docs/HARNESS_SETUP.md' "$TEMP_ROOT/install.log"
assert_contains 'do not start user product tasks yet' "$TEMP_ROOT/install.log"
assert_not_contains 'do not start user product tasks yet' "$fixture_repo/AGENTS.md"

configure_harness "$fixture_repo" "$revision"
rm -f -- "$fixture_repo/docs/exec-plans/active/verify-fixture.md"

expect_status 0 "$fixture_repo/scripts/harness-check.sh" > "$TEMP_ROOT/check.log"
assert_contains "records revision $revision" "$TEMP_ROOT/check.log"
assert_contains "BASELINE [legacy-issues] LEGACY-001" "$TEMP_ROOT/check.log"
assert_contains 'No active execution plan; docs/exec-plans/active may be empty when no task is in progress' "$TEMP_ROOT/check.log"
assert_contains 'PASS [summary]' "$TEMP_ROOT/check.log"
[[ "$(git -C "$fixture_repo" rev-parse HEAD)" == "$revision" ]] || fail "baseline revision moved"
git -C "$fixture_repo" diff --exit-code -- app.sh project-checks README.md

assert_contains 'Takeover chỉ complete khi `./scripts/harness-check.sh` trả exit `0`' "$fixture_repo/docs/HARNESS_SETUP.md"
assert_contains 'không tự tạo task sửa legacy issue' "$fixture_repo/docs/HARNESS_SETUP.md"
assert_contains 'Định nghĩa sẵn sàng' "$fixture_repo/docs/HARNESS_SETUP.md"
assert_contains 'git diff --check' "$fixture_repo/docs/HARNESS_SETUP.md"
assert_contains 'Điểm yếu chưa có failure cụ thể' "$fixture_repo/docs/HARNESS_SETUP.md"
assert_contains 'Không đổi regression thành legacy issue hoặc debt.' "$fixture_repo/docs/HARNESS_SETUP.md"
pass "closed takeover flow preserves source, records legacy evidence, allows idle state, and keeps daily AGENTS free of takeover instructions"

complete_takeover() {
  local target="$1"
  local repo_description="$2"
  local service_command="$3"
  local revision
  local file

  revision="$(git -C "$target" rev-parse HEAD)"
  while IFS= read -r file; do
    sed -i \
      -e "s/{{BASELINE_DATE}}/2026-07-23/g" \
      -e "s/{{BASELINE_GIT_REVISION}}/$revision/g" \
      -e "s/{{REPOSITORY_DESCRIPTION}}/$repo_description/g" \
      -e 's/{{[A-Z0-9_]*}}/configured/g' \
      "$file"
  done < <(find "$target" -type f \( -name '*.md' -o -name 'AGENTS.md' \) -not -path '*/.git/*')

  printf '%s\n' \
    '# Takeover baseline' \
    '' \
    '- Ngày baseline: 2026-07-23' \
    "- Git revision: \`$revision\`" \
    > "$target/docs/TAKEOVER_BASELINE.md"
  printf '%s\n' \
    '' \
    '- Bootstrap: `true`' \
    '- Xác minh: `true`' \
    "- Khởi động app hoặc service: $service_command" \
    '- Mechanical guardrail: `./scripts/harness-check.sh`' \
    >> "$target/docs/VERIFY.md"
  write_v2_metadata "$target" complete "$revision" "2026-07-23T10:00:00Z"
}

new_installed_profile() {
  local target="$1"

  new_git_repo "$target"
  printf 'fixture\n' > "$target/source.txt"
  git -C "$target" add source.txt
  git -C "$target" commit -qm baseline
  install_harness "$target" >/dev/null
}

library_repo="$TEMP_ROOT/library-profile"
new_installed_profile "$library_repo"
expect_status 1 "$library_repo/scripts/harness-check.sh" > "$TEMP_ROOT/library-pending.log"
assert_contains 'WARN [takeover-status] Takeover is pending' "$TEMP_ROOT/library-pending.log"
complete_takeover \
  "$library_repo" \
  "Thư viện shell thuần, không có UI, database hoặc service." \
  "Not applicable — thư viện không khởi động service."
expect_status 0 "$library_repo/scripts/harness-check.sh" > "$TEMP_ROOT/library-complete.log"
assert_contains 'PASS [takeover-status] Takeover is complete.' "$TEMP_ROOT/library-complete.log"
assert_contains 'PASS [summary] Harness configuration is valid.' "$TEMP_ROOT/library-complete.log"
for optional_path in \
  docs/UI.md docs/SECURITY.md docs/specs docs/decisions docs/generated \
  docs/references docs/tasks/active docs/tasks/completed; do
  assert_not_exists "$library_repo/$optional_path"
done
pass "library profile completes takeover with specific not-applicable commands and no optional artifacts"

blocked_repo="$TEMP_ROOT/library-blocked"
cp -a -- "$library_repo" "$blocked_repo"
write_v2_metadata "$blocked_repo" blocked "" "" "Không có quyền đọc private dependency manifest."
expect_status 1 "$blocked_repo/scripts/harness-check.sh" > "$TEMP_ROOT/library-blocked.log"
assert_contains 'BLOCKED [takeover-status] Không có quyền đọc private dependency manifest.' \
  "$TEMP_ROOT/library-blocked.log"
assert_contains 'BLOCKED [summary] Harness takeover has 1 blocker(s).' "$TEMP_ROOT/library-blocked.log"
pass "blocked takeover reports a specific blocker"

malformed_repo="$TEMP_ROOT/library-malformed"
cp -a -- "$library_repo" "$malformed_repo"
printf '{"schema": "harness/installation/v2",\n' > "$malformed_repo/.harness/installation.json"
expect_status 1 "$malformed_repo/scripts/harness-check.sh" > "$TEMP_ROOT/library-malformed.log"
assert_contains 'FAIL [installation-metadata] .harness/installation.json is invalid JSON' \
  "$TEMP_ROOT/library-malformed.log"
pass "malformed takeover metadata fails"

baseline_mismatch_repo="$TEMP_ROOT/library-baseline-mismatch"
cp -a -- "$library_repo" "$baseline_mismatch_repo"
write_v2_metadata "$baseline_mismatch_repo" complete deadbeef "2026-07-23T10:00:00Z"
expect_status 1 "$baseline_mismatch_repo/scripts/harness-check.sh" > "$TEMP_ROOT/library-baseline-mismatch.log"
assert_contains "baseline_revision 'deadbeef' does not match" "$TEMP_ROOT/library-baseline-mismatch.log"
pass "complete takeover rejects a baseline mismatch"

frontend_repo="$TEMP_ROOT/frontend-profile"
new_installed_profile "$frontend_repo"
complete_takeover \
  "$frontend_repo" \
  "Frontend browser cho luồng đăng nhập." \
  "Not applicable — fixture chỉ xác minh static frontend contract."
mkdir -p -- "$frontend_repo/docs/specs"
printf '%s\n' \
  '# Specs' '' '[Sign-in behavior](sign-in.md)' \
  > "$frontend_repo/docs/specs/index.md"
printf '%s\n' \
  '# Sign-in behavior' \
  '## Scope' 'Form `web/sign-in.html`.' \
  '## Observable behavior' 'Submit hợp lệ chuyển sang trạng thái loading rồi success.' \
  '## Acceptance criteria' '`./project-checks/ui.sh` xác minh loading, error và success.' \
  '## Out of scope' 'Token issuance phía backend.' \
  '## Update trigger' 'Cập nhật khi form sign-in hoặc state machine đổi.' \
  > "$frontend_repo/docs/specs/sign-in.md"
printf '%s\n' \
  '# Sign-in UI' \
  '## Surfaces' '`web/sign-in.html` là surface duy nhất.' \
  '## States' 'Idle, loading, validation error và success có output riêng.' \
  '## Interactions' 'Submit chỉ gửi một request khi nút đang enabled.' \
  '## Accessibility' 'Validation error dùng `aria-describedby` trỏ tới message cụ thể.' \
  '## Responsive rules' 'Dưới 40rem form dùng một cột và nút rộng bằng container.' \
  > "$frontend_repo/docs/UI.md"
expect_status 0 "$frontend_repo/scripts/harness-check.sh" > "$TEMP_ROOT/frontend-valid.log"
assert_contains 'PASS [specs]' "$TEMP_ROOT/frontend-valid.log"
assert_contains 'PASS [ui]' "$TEMP_ROOT/frontend-valid.log"
pass "frontend profile passes with repository-specific UI and behavior spec"

frontend_broken="$TEMP_ROOT/frontend-broken-link"
cp -a -- "$frontend_repo" "$frontend_broken"
sed -i 's/sign-in\.md/missing-sign-in.md/' "$frontend_broken/docs/specs/index.md"
expect_status 1 "$frontend_broken/scripts/harness-check.sh" > "$TEMP_ROOT/frontend-broken.log"
assert_contains "docs/specs/index.md points to missing document 'missing-sign-in.md'" \
  "$TEMP_ROOT/frontend-broken.log"
pass "frontend profile fails when its behavior spec link is broken"

backend_repo="$TEMP_ROOT/backend-profile"
new_installed_profile "$backend_repo"
complete_takeover \
  "$backend_repo" \
  "Backend auth sở hữu account records trong PostgreSQL." \
  '`./bin/server` khởi động auth service.'
printf '%s\n' \
  '' \
  '## Data ownership' \
  '`auth-service` là writer duy nhất của bảng `accounts`; consumer chỉ đọc qua API.' \
  >> "$backend_repo/ARCHITECTURE.md"
printf '%s\n' \
  '# Auth security' \
  '## Assets' 'Password hash và session token thuộc auth service.' \
  '## Trust boundaries' '`POST /sessions` nhận credential không tin cậy từ browser.' \
  '## Threats' 'Credential stuffing và session fixation.' \
  '## Controls' '`src/auth/rate-limit` giới hạn attempt và session luôn rotate sau login.' \
  '## Verification' '`./project-checks/security.sh` kiểm tra rate limit và rotation.' \
  > "$backend_repo/docs/SECURITY.md"
mkdir -p -- "$backend_repo/docs/generated"
printf '%s\n' \
  '# Auth schema' \
  '- Source: `db/schema.sql`' \
  '- Generator command: `./bin/generate-schema-docs`' \
  '- Generator version: `schema-docs 2.0`' \
  '- Applies to: `accounts` và `sessions`' \
  '- Refresh trigger: chạy lại khi migration DB thay đổi' \
  > "$backend_repo/docs/generated/auth-schema.md"
backend_revision="$(git -C "$backend_repo" rev-parse HEAD)"
printf '%s\n' \
  '# Legacy issues' '' \
  '### `LEGACY-001`: bcrypt cost thấp tại baseline' '' \
  '- Failure signature: `bcrypt cost 8 is below policy 10`' \
  '- Impact: hash cũ cần rehash sau login.' \
  '- Status: Accepted' \
  "- Baseline revision: \`$backend_revision\`" \
  '- Baseline evidence: `./project-checks/security.sh` exit 1 tại baseline.' \
  '- Reproduction command / steps: `./project-checks/security.sh`' \
  > "$backend_repo/docs/LEGACY_ISSUES.md"
expect_status 0 "$backend_repo/scripts/harness-check.sh" > "$TEMP_ROOT/backend-valid.log"
assert_contains 'PASS [security]' "$TEMP_ROOT/backend-valid.log"
assert_contains 'PASS [generated]' "$TEMP_ROOT/backend-valid.log"
assert_contains 'BASELINE [legacy-issues] LEGACY-001' "$TEMP_ROOT/backend-valid.log"
assert_contains 'Data ownership' "$backend_repo/ARCHITECTURE.md"
pass "backend auth and DB profile validates security, data ownership, generated provenance, and baseline legacy classification"

backend_ungenerated="$TEMP_ROOT/backend-ungenerated-schema"
cp -a -- "$backend_repo" "$backend_ungenerated"
sed -i '/^- Generator command:/d' "$backend_ungenerated/docs/generated/auth-schema.md"
expect_status 1 "$backend_ungenerated/scripts/harness-check.sh" > "$TEMP_ROOT/backend-ungenerated.log"
assert_contains 'has no configured' "$TEMP_ROOT/backend-ungenerated.log"
assert_contains 'Generator command or Command' "$TEMP_ROOT/backend-ungenerated.log"
pass "backend generated schema fails without a generator"
