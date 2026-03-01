#!/usr/bin/env bash

set -uo pipefail

BAZEL="${BAZEL:-bazelisk}"

verify_coverage() {
    local version=${1:-$(cat .ruby-version)}

    if [[ "$version" == *"truffleruby"* ]]; then
        echo "Skipping coverage test for TruffleRuby ($version)"
        return 0
    fi

    echo "Testing coverage for $version..."
    if [ $# -gt 0 ]; then
        echo "$version" > .ruby-version
    fi

    rm -f bazel-testlogs/spec/add/coverage.dat

    $BAZEL coverage //spec:add --test_output=errors || {
        echo "ERROR: Bazel coverage failed for $version"
        return 1
    }

    local coverage_file="bazel-testlogs/spec/add/coverage.dat"
    if [ -f "$coverage_file" ] && [ -s "$coverage_file" ]; then
        echo "SUCCESS: Found valid coverage report for $version"
        return 0
    else
        echo "ERROR: Missing or empty coverage report for $version"
        return 1
    fi
}

# If arguments are provided, test those specific versions.
# Otherwise, test the current environment.
if [ $# -gt 0 ]; then
    for ver in "$@"; do
        verify_coverage "$ver" || exit 1
    done
else
    verify_coverage || exit 1
fi

exit 0
