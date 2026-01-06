#!/usr/bin/env bash

# Tests for generate_rv_checksums.sh

# --- begin runfiles.bash initialization v3 ---
# Copy-pasted from the Bazel Bash runfiles library v3.
set -uo pipefail
set +e
f=bazel_tools/tools/bash/runfiles/runfiles.bash
# shellcheck disable=SC1090
source "${RUNFILES_DIR:-/dev/null}/$f" 2>/dev/null \
  || source "$(grep -sm1 "^$f " "${RUNFILES_MANIFEST_FILE:-/dev/null}" | cut -f2- -d' ')" 2>/dev/null \
  || source "$0.runfiles/$f" 2>/dev/null \
  || source "$(grep -sm1 "^$f " "$0.runfiles_manifest" | cut -f2- -d' ')" 2>/dev/null \
  || source "$(grep -sm1 "^$f " "$0.exe.runfiles_manifest" | cut -f2- -d' ')" 2>/dev/null \
  || {
    echo >&2 "ERROR: ${BASH_SOURCE[0]} cannot find $f"
    exit 1
  }
f=
set -e
# --- end runfiles.bash initialization v3 ---

# MARK - Locate Deps

assertions_sh_location=cgrindel_bazel_starlib/shlib/lib/assertions.sh
assertions_sh="$(rlocation "${assertions_sh_location}")" \
  || (echo >&2 "Failed to locate ${assertions_sh_location}" && exit 1)
# shellcheck disable=SC1090
source "${assertions_sh}"

generate_rv_checksums_location=rules_ruby/tools/generate_rv_checksums/generate_rv_checksums.sh
generate_rv_checksums="$(rlocation "${generate_rv_checksums_location}")"

mock_response_location=rules_ruby/tools/generate_rv_checksums/testdata/rv_ruby_release_response.json
mock_response="$(rlocation "${mock_response_location}")"

expected_output_location=rules_ruby/tools/generate_rv_checksums/testdata/expected_checksums_output.txt
expected_output="$(rlocation "${expected_output_location}")"

# MARK - Cleanup

# Collect temp directories for cleanup
temp_dirs=()
cleanup_temp_dirs() {
  for dir in "${temp_dirs[@]:-}"; do
    rm -rf "${dir}"
  done
}
trap cleanup_temp_dirs EXIT

# MARK - Tests

# Test 1: Basic dry-run with .ruby-version
test_basic_dry_run() {
  echo "TEST: Basic dry-run with .ruby-version"

  local temp_dir
  temp_dir="$(mktemp -d)"
  temp_dirs+=("${temp_dir}")

  cd "${temp_dir}"
  export BUILD_WORKSPACE_DIRECTORY="${temp_dir}"

  # Setup .ruby-version
  echo "3.4.8" >.ruby-version

  # Mock the API response
  export RV_RUBY_API_URL="file://${mock_response%/*}"

  # Run the script
  local output
  output=$("${generate_rv_checksums}" 20251225 --dry-run)

  # Verify output matches expected
  local expected
  expected=$(cat "${expected_output}")

  assert_equal "${expected}" "${output}" "Output should match expected checksums"

  echo "PASS: Basic dry-run with .ruby-version"
}

# Test 2: Explicit Ruby version
test_explicit_ruby_version() {
  echo "TEST: Explicit Ruby version"

  local temp_dir
  temp_dir="$(mktemp -d)"
  temp_dirs+=("${temp_dir}")

  cd "${temp_dir}"
  export BUILD_WORKSPACE_DIRECTORY="${temp_dir}"

  # Mock the API response
  export RV_RUBY_API_URL="file://${mock_response%/*}"

  # Run the script with explicit version
  local output
  output=$("${generate_rv_checksums}" 20251225 --ruby-version 3.4.8 --dry-run)

  # Verify output contains expected checksums
  assert_match "linux-arm64" "${output}" "Output should contain linux-arm64"
  assert_match "0c08c35a99f10817643d548f98012268c5433ae25a737ab4d6751336108a941d" "${output}" \
    "Output should contain correct checksum"

  echo "PASS: Explicit Ruby version"
}

# Test 3: Missing .ruby-version without --ruby-version
test_missing_ruby_version() {
  echo "TEST: Missing .ruby-version without --ruby-version"

  local temp_dir
  temp_dir="$(mktemp -d)"
  temp_dirs+=("${temp_dir}")

  cd "${temp_dir}"
  export BUILD_WORKSPACE_DIRECTORY="${temp_dir}"

  # Don't create .ruby-version file

  # Mock the API response
  export RV_RUBY_API_URL="file://${mock_response%/*}"

  # Run the script and expect failure
  if "${generate_rv_checksums}" 20251225 --dry-run 2>/dev/null; then
    fail "Should have failed when .ruby-version is missing"
  fi

  echo "PASS: Missing .ruby-version without --ruby-version"
}

# Test 4: Invalid rv_version
test_invalid_rv_version() {
  echo "TEST: Invalid rv_version"

  local temp_dir
  temp_dir="$(mktemp -d)"
  temp_dirs+=("${temp_dir}")

  cd "${temp_dir}"
  export BUILD_WORKSPACE_DIRECTORY="${temp_dir}"

  # Use a non-existent API URL to simulate 404
  export RV_RUBY_API_URL="file:///nonexistent"

  # Run the script and expect failure
  if "${generate_rv_checksums}" 99999999 --ruby-version 3.4.8 --dry-run 2>/dev/null; then
    fail "Should have failed for invalid rv_version"
  fi

  echo "PASS: Invalid rv_version"
}

# Run all tests
test_basic_dry_run
test_explicit_ruby_version
test_missing_ruby_version
test_invalid_rv_version

echo ""
echo "All tests passed!"
