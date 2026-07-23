#!/usr/bin/env bash

set -u
set -o pipefail

TEST_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
SOURCE_ROOT="$(cd -- "$TEST_DIR/.." && pwd -P)"
TEMP_ROOT=""

fail() {
  printf 'FAIL: %s\n' "$1" >&2
  exit 1
}

pass() {
  printf 'PASS: %s\n' "$1"
}

assert_file() {
  [[ -f "$1" ]] || fail "expected file: $1"
}

assert_not_exists() {
  [[ ! -e "$1" && ! -L "$1" ]] || fail "expected path to be absent: $1"
}

assert_contains() {
  local needle="$1"
  local file="$2"
  grep -Fq -- "$needle" "$file" || fail "expected '$needle' in $file"
}

assert_not_contains() {
  local needle="$1"
  local file="$2"
  if grep -Fq -- "$needle" "$file"; then
    fail "did not expect '$needle' in $file"
  fi
}

new_temp_root() {
  TEMP_ROOT="$(mktemp -d)" || fail "cannot create temporary directory"
  trap 'rm -rf -- "$TEMP_ROOT"' EXIT
}

new_git_repo() {
  local path="$1"
  mkdir -p -- "$path"
  git -C "$path" init -q
  git -C "$path" config user.email fixture@example.invalid
  git -C "$path" config user.name "Harness Fixture"
}

install_harness() {
  local target="$1"
  shift
  "$SOURCE_ROOT/install.sh" --target "$target" "$@"
}

configure_harness() {
  local target="$1"
  local revision="$2"
  local file

  while IFS= read -r file; do
    [[ -f "$file" ]] || continue
    sed -i \
      -e "s/{{BASELINE_DATE}}/2026-07-17/g" \
      -e "s/{{BASELINE_GIT_REVISION}}/$revision/g" \
      -e 's/{{[A-Z0-9_]*}}/configured/g' \
      "$file"
  done < <(find "$target" -type f \( -name '*.md' -o -name 'AGENTS.md' \) -not -path '*/.git/*')

  mkdir -p -- "$target/docs/exec-plans/active"
  printf '%s\n' \
    '# Verify legacy fixture' \
    '' \
    '- Mục tiêu: bảo toàn source và so sánh mọi thay đổi với baseline.' \
    '- Xác minh: `./project-checks/build.sh` và `./scripts/harness-check.sh`.' \
    '- Regression sau baseline phải được sửa, không được thêm vào legacy issues.' \
    > "$target/docs/exec-plans/active/verify-fixture.md"

  printf '%s\n' \
    '# LEGACY_ISSUES.md' \
    '' \
    '### `LEGACY-001`: Greeting punctuation test fails' \
    '' \
    '- Area: greeting output' \
    '- Failure signature: `FAIL legacy greeting preserves deprecated punctuation`' \
    '- Impact: compatibility assertion remains red at takeover' \
    '- Status: Accepted' \
    "- Baseline revision: \`$revision\`" \
    '- Baseline evidence: `./project-checks/test.sh` exited 1 at the baseline revision' \
    '- Reproduction command / steps: `./project-checks/test.sh`' \
    '- Active plan hoặc resolution evidence: tracked outside current scope' \
    > "$target/docs/LEGACY_ISSUES.md"

  printf '%s\n' '| fixture | `A` | configured | configured | configured | configured | 2026-07-17 |' \
    >> "$target/docs/QUALITY_SCORE.md"
}

make_configured_repo() {
  local target="$1"
  local revision

  new_git_repo "$target"
  printf 'fixture\n' > "$target/source.txt"
  git -C "$target" add source.txt
  git -C "$target" commit -qm baseline
  revision="$(git -C "$target" rev-parse HEAD)"
  install_harness "$target" >/dev/null
  configure_harness "$target" "$revision"
}

make_v1_repo() {
  make_configured_repo "$1"
}

expect_status() {
  local expected="$1"
  shift
  local actual

  set +e
  "$@"
  actual=$?
  set -e
  [[ "$actual" -eq "$expected" ]] || fail "expected exit $expected, got $actual: $*"
}
