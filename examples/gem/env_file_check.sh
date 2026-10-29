#!/usr/bin/env bash
set -euo pipefail

grep -q '"RULES_RUBY_ENV_FILE_TEST": "exercised"' "$1" || {
    echo "env_file value not found in the generated bundle repository BUILD file:" >&2
    cat "$1" >&2
    exit 1
}
