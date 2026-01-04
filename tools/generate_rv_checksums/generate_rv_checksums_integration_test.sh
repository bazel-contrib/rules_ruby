#!/usr/bin/env bash

# Integration tests for generate_rv_checksums.sh that verify buildozer updates
# work

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

echo "DEBUG: Starting to locate dependencies"

assertions_sh_location=cgrindel_bazel_starlib/shlib/lib/assertions.sh
assertions_sh="$(rlocation "${assertions_sh_location}")" \
  || (echo >&2 "Failed to locate ${assertions_sh_location}" && exit 1)
echo "DEBUG: Found assertions_sh at ${assertions_sh}"
# shellcheck disable=SC1090
source "${assertions_sh}"
echo "DEBUG: Sourced assertions_sh"

generate_rv_checksums_location=rules_ruby/tools/generate_rv_checksums/generate_rv_checksums.sh
generate_rv_checksums="$(rlocation "${generate_rv_checksums_location}")"

mock_response_location=rules_ruby/tools/generate_rv_checksums/testdata/rv_ruby_release_response.json
mock_response="$(rlocation "${mock_response_location}")"

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

# Test: Buildozer updates MODULE.bazel correctly
test_buildozer_updates() {
  echo "TEST: Buildozer updates MODULE.bazel correctly"

  local temp_dir
  temp_dir="$(mktemp -d)"
  temp_dirs+=("${temp_dir}")

  cd "${temp_dir}"
  export BUILD_WORKSPACE_DIRECTORY="${temp_dir}"

  # Create a minimal Bazel workspace
  cat >WORKSPACE.bazel <<'EOF'
# Empty workspace for testing
EOF

  cat >MODULE.bazel <<'EOF'
module(name = "test_workspace")

ruby = use_extension("@rules_ruby//ruby:extensions.bzl", "ruby")

ruby.toolchain(
    name = "ruby",
    ruby_version = "3.3.0",
)

use_repo(ruby, "ruby_toolchains")
EOF

  # Mock the API response
  export RV_RUBY_API_URL="file://${mock_response%/*}"

  # DEBUG BEGIN
  echo >&2 "*** CHUCK $(basename "${BASH_SOURCE[0]}") BEFORE generate_rv_checksums"
  # DEBUG END

  # Run the script WITHOUT --dry-run
  "${generate_rv_checksums}" 20251225 --ruby-version 3.4.8 \
    --module-bazel MODULE.bazel

  # DEBUG BEGIN
  echo >&2 "*** CHUCK $(basename "${BASH_SOURCE[0]}") AFTER generate_rv_checksums"
  # DEBUG END

  # Verify MODULE.bazel was updated
  local module_content
  module_content=$(cat MODULE.bazel)

  # Check rv_version was set
  assert_match 'rv_version = "20251225"' "${module_content}" \
    "MODULE.bazel should contain rv_version"

  # Check rv_checksums was set with all platforms
  assert_match "rv_checksums = {" "${module_content}" \
    "MODULE.bazel should contain rv_checksums"
  assert_match \
    '"linux-arm64": "0c08c35a99f10817643d548f98012268c5433ae25a737ab4d6751336108a941d"' \
    "${module_content}" \
    "MODULE.bazel should contain linux-arm64 checksum"
  assert_match \
    '"linux-x86_64": "f36cef10365d370e0867f0c3ac36e457a26ab04f3cfbbd7edb227a18e6e9b3c3"' \
    "${module_content}" \
    "MODULE.bazel should contain linux-x86_64 checksum"
  assert_match \
    '"macos-arm64": "cd9d7a1428076bfcc6c2ca3c0eb69b8e671e9b48afb4c351fa4a84927841ffef"' \
    "${module_content}" \
    "MODULE.bazel should contain macos-arm64 checksum"
  assert_match \
    '"macos-x86_64": "e9da39082d1dd8502d322c850924d929bc45b7a1e35da593a5606c00673218d4"' \
    "${module_content}" \
    "MODULE.bazel should contain macos-x86_64 checksum"

  # Verify ruby_version was NOT changed (we didn't update it)
  assert_match 'ruby_version = "3.3.0"' "${module_content}" \
    "MODULE.bazel should preserve existing ruby_version"

  echo "PASS: Buildozer updates MODULE.bazel correctly"
}

# Test: Buildozer updates only target toolchain by name
test_buildozer_name_filtering() {
  echo "TEST: Buildozer updates only target toolchain by name"

  local temp_dir
  temp_dir="$(mktemp -d)"
  temp_dirs+=("${temp_dir}")

  cd "${temp_dir}"
  export BUILD_WORKSPACE_DIRECTORY="${temp_dir}"

  # Create workspace with multiple toolchains
  cat >WORKSPACE.bazel <<'EOF'
# Empty workspace for testing
EOF

  cat >MODULE.bazel <<'EOF'
module(name = "test_workspace")

ruby = use_extension("@rules_ruby//ruby:extensions.bzl", "ruby")

ruby.toolchain(
    name = "ruby",
    ruby_version = "3.3.0",
)

ruby.toolchain(
    name = "ruby_alt",
    ruby_version = "3.2.0",
)

use_repo(ruby, "ruby_toolchains")
EOF

  # Mock the API response
  export RV_RUBY_API_URL="file://${mock_response%/*}"

  # Run the script for "ruby_alt" toolchain
  "${generate_rv_checksums}" 20251225 --ruby-version 3.4.8 --name ruby_alt \
    --module-bazel MODULE.bazel

  # Verify MODULE.bazel was updated
  local module_content
  module_content=$(cat MODULE.bazel)

  # Count how many rv_version assignments there are
  local rv_version_count
  rv_version_count=$(grep -c 'rv_version = "20251225"' MODULE.bazel || true)

  assert_equal "1" "${rv_version_count}" \
    'Should have exactly one rv_version = "20251225" (only in ruby_alt)'

  # Verify the first toolchain (ruby) was NOT updated
  # Check that there's still a toolchain without rv_version before ruby_alt
  if ! grep -B5 'name = "ruby_alt"' MODULE.bazel | grep -q 'name = "ruby"'; then
    fail "First toolchain should still exist"
  fi

  echo "PASS: Buildozer updates only target toolchain by name"
}

# Run all tests
test_buildozer_updates
test_buildozer_name_filtering

echo ""
echo "All integration tests passed!"
