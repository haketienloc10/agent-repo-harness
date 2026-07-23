#!/usr/bin/env bash

set -euo pipefail

TEST_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"

for test_script in \
  test-installer.sh test-checker.sh test-task-friction.sh test-migration.sh \
  test-e2e.sh test-e2e-upgrade.sh; do
  printf '\n==> %s\n' "$test_script"
  bash "$TEST_DIR/$test_script"
done

printf '\nAll installer, checker, task-friction, migration, and end-to-end tests passed.\n'
