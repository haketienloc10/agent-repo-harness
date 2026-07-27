#!/usr/bin/env bash

set -euo pipefail

TEST_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"

for test_script in \
  test-installer.sh \
  test-checker.sh \
  test-migration.sh \
  test-e2e.sh \
  test-e2e-upgrade.sh \
  test-workspace-qiqi.sh; do
  printf '\n==> %s\n' "$test_script"
  bash "$TEST_DIR/$test_script"
done

printf '\nAll installer, checker, migration, end-to-end, and workspace tests passed.\n'
