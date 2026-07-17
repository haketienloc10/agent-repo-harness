#!/usr/bin/env bash

set -u

name="${1:-world}"
printf 'Hello, %s\n' "$name"
