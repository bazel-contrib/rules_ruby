#!/usr/bin/env bash

# Tests for generate_excluded_gems.sh

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

generate_excluded_gems_location=rules_ruby/tools/generate_excluded_gems/generate_excluded_gems.sh
generate_excluded_gems="$(rlocation "${generate_excluded_gems_location}")"

mock_response_location=rules_ruby/tools/generate_excluded_gems/testdata/default_gems.json
mock_response="$(rlocation "${mock_response_location}")"

expected_output_location=rules_ruby/tools/generate_excluded_gems/testdata/expected_excluded_gems_output.txt
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

  # Mock the stdgems response
  export STDGEMS_URL="file://${mock_response}"

  # Run the script
  local output
  output=$("${generate_excluded_gems}" --dry-run)

  # Verify output matches expected
  local expected
  expected=$(cat "${expected_output}")

  assert_equal "${expected}" "${output}" \
    "Output should match expected excluded gems"

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

  # Mock the stdgems response
  export STDGEMS_URL="file://${mock_response}"

  # Run the script with explicit version
  local output
  output=$("${generate_excluded_gems}" --ruby-version 3.4.8 --dry-run)

  # Verify output contains expected gems
  assert_match "psych" "${output}" "Output should contain psych"
  assert_match "json" "${output}" "Output should contain json"

  # Should NOT contain non-native gems
  if echo "${output}" | grep -q "csv"; then
    fail "Output should not contain csv (non-native gem)"
  fi

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

  # Mock the stdgems response
  export STDGEMS_URL="file://${mock_response}"

  # Run the script and expect failure
  if "${generate_excluded_gems}" --dry-run 2>/dev/null; then
    fail "Should have failed when .ruby-version is missing"
  fi

  echo "PASS: Missing .ruby-version without --ruby-version"
}

# Test 4: Ruby version not in stdgems data
test_unsupported_ruby_version() {
  echo "TEST: Ruby version not in stdgems data"

  local temp_dir
  temp_dir="$(mktemp -d)"
  temp_dirs+=("${temp_dir}")

  cd "${temp_dir}"
  export BUILD_WORKSPACE_DIRECTORY="${temp_dir}"

  # Mock the stdgems response
  export STDGEMS_URL="file://${mock_response}"

  # Run the script with unsupported version and expect failure
  generate_excluded_gems_cmd=(
    "${generate_excluded_gems}" --ruby-version 1.0.0 --dry-run
  )
  if "${generate_excluded_gems_cmd[@]}" 2>/dev/null; then
    fail "Should have failed for unsupported Ruby version"
  fi

  echo "PASS: Ruby version not in stdgems data"
}

# Test 5: Ruby 3.3 version
test_ruby_33_version() {
  echo "TEST: Ruby 3.3 version"

  local temp_dir
  temp_dir="$(mktemp -d)"
  temp_dirs+=("${temp_dir}")

  cd "${temp_dir}"
  export BUILD_WORKSPACE_DIRECTORY="${temp_dir}"

  # Mock the stdgems response
  export STDGEMS_URL="file://${mock_response}"

  # Run the script with 3.3.x version
  local output
  output=$("${generate_excluded_gems}" --ruby-version 3.3.0 --dry-run)

  # Verify output contains expected gems (same ones exist for 3.3)
  assert_match "psych" "${output}" "Output should contain psych"
  assert_match "json" "${output}" "Output should contain json"

  echo "PASS: Ruby 3.3 version"
}

# Run all tests
test_basic_dry_run
test_explicit_ruby_version
test_missing_ruby_version
test_unsupported_ruby_version
test_ruby_33_version

echo ""
echo "All tests passed!"
