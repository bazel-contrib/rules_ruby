#!/usr/bin/env bash

# Integration tests for generate_excluded_gems.sh that verify buildozer updates work

set -o errexit -o nounset -o pipefail

# --- begin runfiles.bash initialization v3 ---
# Copy-pasted from the Bazel Bash runfiles library v3.
set -uo pipefail
set +e
f=bazel_tools/tools/bash/runfiles/runfiles.bash
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

ruby.bundle_fetch(
    name = "bundle",
    gemfile = "//:Gemfile",
    gemfile_lock = "//:Gemfile.lock",
)

use_repo(ruby, "bundle")
EOF

  # Mock the stdgems response
  export STDGEMS_URL="file://${mock_response}"

  # Run the script WITHOUT --dry-run
  "${generate_excluded_gems}" --ruby-version 3.4.8 --module-bazel MODULE.bazel

  # Verify MODULE.bazel was updated
  local module_content
  module_content=$(cat MODULE.bazel)

  # Check excluded_gems was set with expected gems
  assert_match "excluded_gems = \[" "${module_content}" \
    "MODULE.bazel should contain excluded_gems list"
  assert_match '"date"' "${module_content}" \
    "MODULE.bazel should contain date gem"
  assert_match '"digest"' "${module_content}" \
    "MODULE.bazel should contain digest gem"
  assert_match '"json"' "${module_content}" \
    "MODULE.bazel should contain json gem"
  assert_match '"psych"' "${module_content}" \
    "MODULE.bazel should contain psych gem"

  # Verify gemfile was NOT changed
  assert_match 'gemfile = "//:Gemfile"' "${module_content}" \
    "MODULE.bazel should preserve existing gemfile"

  echo "PASS: Buildozer updates MODULE.bazel correctly"
}

# Test: Buildozer updates only target bundle by name
test_buildozer_name_filtering() {
  echo "TEST: Buildozer updates only target bundle by name"

  local temp_dir
  temp_dir="$(mktemp -d)"
  temp_dirs+=("${temp_dir}")

  cd "${temp_dir}"
  export BUILD_WORKSPACE_DIRECTORY="${temp_dir}"

  # Create workspace with multiple bundle_fetch calls
  cat >WORKSPACE.bazel <<'EOF'
# Empty workspace for testing
EOF

  cat >MODULE.bazel <<'EOF'
module(name = "test_workspace")

ruby = use_extension("@rules_ruby//ruby:extensions.bzl", "ruby")

ruby.bundle_fetch(
    name = "bundle",
    gemfile = "//:Gemfile",
    gemfile_lock = "//:Gemfile.lock",
)

ruby.bundle_fetch(
    name = "bundle_alt",
    gemfile = "//alt:Gemfile",
    gemfile_lock = "//alt:Gemfile.lock",
)

use_repo(ruby, "bundle", "bundle_alt")
EOF

  # Mock the stdgems response
  export STDGEMS_URL="file://${mock_response}"

  # Run the script for "bundle_alt"
  "${generate_excluded_gems}" --ruby-version 3.4.8 --name bundle_alt \
    --module-bazel MODULE.bazel

  # Verify MODULE.bazel was updated
  local module_content
  module_content=$(cat MODULE.bazel)

  # Count how many excluded_gems assignments there are
  local excluded_gems_count
  excluded_gems_count=$(grep -c "excluded_gems = \[" MODULE.bazel || true)

  assert_equal "1" "${excluded_gems_count}" \
    'Should have exactly one excluded_gems list (only in bundle_alt)'

  # Verify the first bundle_fetch (bundle) was NOT updated
  # Check that there's still a bundle_fetch without excluded_gems before
  # bundle_alt
  if ! grep -B5 'name = "bundle_alt"' MODULE.bazel | grep -q 'name = "bundle"'; then
    fail "First bundle_fetch should still exist"
  fi

  echo "PASS: Buildozer updates only target bundle by name"
}

# Run all tests
test_buildozer_updates
test_buildozer_name_filtering

echo ""
echo "All integration tests passed!"
