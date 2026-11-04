#!/usr/bin/env bash
set -euo pipefail

if grep -q -e 'BUNDLE_BUILD__PSYCH' -e 'BUNDLE_BUILD__OPENSSL' -e '--with-libyaml-dir=/' -e '--with-openssl-dir=/' "$1"; then
    echo "launcher embeds build-time Bundler options or absolute dist paths:" >&2
    grep -e 'BUNDLE_BUILD__' -e '--with-.*-dir=' "$1" >&2
    exit 1
fi
