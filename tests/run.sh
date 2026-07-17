#!/usr/bin/env bash

set -euo pipefail

TEST_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"

for test_script in test-installer.sh test-checker.sh test-e2e.sh; do
  printf '\n==> %s\n' "$test_script"
  "$TEST_DIR/$test_script"
done

printf '\nAll installer, checker, and end-to-end tests passed.\n'
