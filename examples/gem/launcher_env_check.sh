#!/usr/bin/env bash
set -euo pipefail

# TruffleRuby legitimately records Homebrew prefixes, so only look for paths
# into the downloaded Ruby's `dist/` directory.
if grep -q -E -e '--with-(libyaml|openssl)-dir=[^ ]*/dist' "$1"; then
    echo "launcher embeds build-time Bundler options or absolute dist paths:" >&2
    grep -E -e '--with-(libyaml|openssl)-dir=[^ ]*/dist' "$1" >&2
    exit 1
fi
