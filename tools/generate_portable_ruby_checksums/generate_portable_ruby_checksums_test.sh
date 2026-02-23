#!/usr/bin/env bash

# Tests for generate_portable_ruby_checksums.sh

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

generate_portable_ruby_checksums_location=rules_ruby/tools/generate_portable_ruby_checksums/generate_portable_ruby_checksums.sh
generate_portable_ruby_checksums="$(rlocation "${generate_portable_ruby_checksums_location}")"

mock_response_location=rules_ruby/tools/generate_portable_ruby_checksums/testdata/jdx_ruby_release_response.json
mock_response="$(rlocation "${mock_response_location}")"

expected_output_location=rules_ruby/tools/generate_portable_ruby_checksums/testdata/expected_checksums_output.txt
expected_output="$(rlocation "${expected_output_location}")"

releases_list_location=rules_ruby/tools/generate_portable_ruby_checksums/testdata/jdx_ruby_releases_list.json
releases_list="$(rlocation "${releases_list_location}")"

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

  local temp_dir
  temp_dir="$(mktemp -d)"
  temp_dirs+=("${temp_dir}")

  cd "${temp_dir}"
  export BUILD_WORKSPACE_DIRECTORY="${temp_dir}"

  # Setup .ruby-version
  echo "3.4.8" >.ruby-version

  # Mock the API response (the release tag is the Ruby version)
  export RV_RUBY_API_URL="file://${mock_response%/*}"

  # Run the script
  local output
  output=$("${generate_portable_ruby_checksums}" --dry-run)

  # Verify output matches expected
  local expected
  expected=$(cat "${expected_output}")

  assert_equal "${expected}" "${output}" "Output should match expected checksums"

}

# Test 2: Explicit Ruby version
test_explicit_ruby_version() {

  local temp_dir
  temp_dir="$(mktemp -d)"
  temp_dirs+=("${temp_dir}")

  cd "${temp_dir}"
  export BUILD_WORKSPACE_DIRECTORY="${temp_dir}"

  # Mock the API response
  export RV_RUBY_API_URL="file://${mock_response%/*}"

  # Run the script with explicit version
  local output
  output=$("${generate_portable_ruby_checksums}" --ruby-version 3.4.8 --dry-run)

  # Verify output contains expected checksums
  assert_match "arm64_linux" "${output}" "Output should contain arm64_linux"
  assert_match "0c08c35a99f10817643d548f98012268c5433ae25a737ab4d6751336108a941d" "${output}" \
    "Output should contain correct checksum"

}

# Test 3: Missing .ruby-version without --ruby-version
test_missing_ruby_version() {

  local temp_dir
  temp_dir="$(mktemp -d)"
  temp_dirs+=("${temp_dir}")

  cd "${temp_dir}"
  export BUILD_WORKSPACE_DIRECTORY="${temp_dir}"

  # Don't create .ruby-version file

  # Mock the API response
  export RV_RUBY_API_URL="file://${mock_response%/*}"

  # Run the script and expect failure
  if "${generate_portable_ruby_checksums}" --dry-run 2>/dev/null; then
    fail "Should have failed when .ruby-version is missing"
  fi

}

# Test 4: Invalid Ruby version (release not found)
test_invalid_ruby_version() {

  local temp_dir
  temp_dir="$(mktemp -d)"
  temp_dirs+=("${temp_dir}")

  cd "${temp_dir}"
  export BUILD_WORKSPACE_DIRECTORY="${temp_dir}"

  # Use a non-existent API URL to simulate 404
  export RV_RUBY_API_URL="file:///nonexistent"

  # Run the script and expect failure
  if "${generate_portable_ruby_checksums}" --ruby-version 99.99.99 --dry-run 2>/dev/null; then
    fail "Should have failed for invalid Ruby version"
  fi

}

# Test 5: --all flag fails outside rules_ruby repo
test_all_requires_rules_ruby_repo() {

  local temp_dir
  temp_dir="$(mktemp -d)"
  temp_dirs+=("${temp_dir}")

  cd "${temp_dir}"
  export BUILD_WORKSPACE_DIRECTORY="${temp_dir}"

  # Create a MODULE.bazel with a different module name
  cat >"${temp_dir}/MODULE.bazel" <<'EOF'
module(name = "some_other_repo")
EOF

  export RV_RUBY_LIST_API_URL="file://${releases_list}"

  # Should fail because module name is not rules_ruby
  if "${generate_portable_ruby_checksums}" --all --dry-run 2>/dev/null; then
    fail "Should have failed when not in rules_ruby repo"
  fi

}

# Test 6: --all flag dry-run generates correct bzl content
test_all_dry_run() {

  local temp_dir
  temp_dir="$(mktemp -d)"
  temp_dirs+=("${temp_dir}")

  cd "${temp_dir}"
  export BUILD_WORKSPACE_DIRECTORY="${temp_dir}"

  # Satisfy the rules_ruby repo check
  printf 'module(name = "rules_ruby")\n' >"${temp_dir}/MODULE.bazel"

  # Mock the releases list API response
  export RV_RUBY_LIST_API_URL="file://${releases_list}"

  # Run the script with --all --dry-run
  local output
  output=$("${generate_portable_ruby_checksums}" --all --dry-run)

  # Verify output is a valid bzl file
  assert_match 'PORTABLE_RUBY_CHECKSUMS =' "${output}" \
    "Output should contain PORTABLE_RUBY_CHECKSUMS dict"

  # Verify no_yjit entries are excluded
  if echo "${output}" | grep -q "no_yjit"; then
    fail "Output should not contain no_yjit entries"
  fi

  # Verify both versions are present
  assert_match "ruby-3.4.8" "${output}" "Output should contain 3.4.8 checksums"
  assert_match "ruby-3.4.7" "${output}" "Output should contain 3.4.7 checksums"

  # Verify entries are sorted in reverse order (3.4.8 before 3.4.7)
  local pos_348 pos_347
  pos_348=$(echo "${output}" | grep -n "ruby-3.4.8" | head -1 | cut -d: -f1)
  pos_347=$(echo "${output}" | grep -n "ruby-3.4.7" | head -1 | cut -d: -f1)
  if [[ ${pos_348} -gt ${pos_347} ]]; then
    fail "Entries should be in reverse order (3.4.8 before 3.4.7)"
  fi

}

# Test 7: --all flag writes bzl file
test_all_writes_bzl_file() {

  local temp_dir
  temp_dir="$(mktemp -d)"
  temp_dirs+=("${temp_dir}")

  cd "${temp_dir}"
  export BUILD_WORKSPACE_DIRECTORY="${temp_dir}"

  # Satisfy the rules_ruby repo check
  printf 'module(name = "rules_ruby")\n' >"${temp_dir}/MODULE.bazel"

  # Mock the releases list API response
  export RV_RUBY_LIST_API_URL="file://${releases_list}"

  # Run the script with --all and a custom output path
  local output_file="${temp_dir}/checksums.bzl"
  "${generate_portable_ruby_checksums}" --all --checksums-bzl "${output_file}"

  # Verify the file was written
  if [[ ! -f ${output_file} ]]; then
    fail "Checksums bzl file should have been written"
  fi

  local content
  content=$(cat "${output_file}")

  assert_match 'PORTABLE_RUBY_CHECKSUMS =' "${content}" \
    "File should contain PORTABLE_RUBY_CHECKSUMS dict"
  assert_match "ruby-3.4.8.x86_64_linux.tar.gz" "${content}" \
    "File should contain x86_64_linux entry"

}

# Run all tests
test_basic_dry_run
test_explicit_ruby_version
test_missing_ruby_version
test_invalid_ruby_version
test_all_requires_rules_ruby_repo
test_all_dry_run
test_all_writes_bzl_file
