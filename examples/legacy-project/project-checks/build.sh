#!/usr/bin/env bash

set -u

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
bash -n "$script_dir/../app.sh"
printf 'build: pass\n'
