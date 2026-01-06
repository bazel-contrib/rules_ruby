#!/usr/bin/env bash

# Generates excluded_gems for ruby.bundle_fetch() and updates MODULE.bazel.

# --- begin runfiles.bash initialization v3 ---
# Copy-pasted from the Bazel Bash runfiles library v3.
set -uo pipefail
set +e
f=bazel_tools/tools/bash/runfiles/runfiles.bash
# shellcheck disable=SC1090
source "${RUNFILES_DIR:-/dev/null}/${f}" 2>/dev/null \
  || source "$(grep -sm1 "^${f} " "${RUNFILES_MANIFEST_FILE:-/dev/null}" | cut -f2- -d' ')" 2>/dev/null \
  || source "$0.runfiles/${f}" 2>/dev/null \
  || source "$(grep -sm1 "^${f} " "$0.runfiles_manifest" | cut -f2- -d' ')" 2>/dev/null \
  || source "$(grep -sm1 "^${f} " "$0.exe.runfiles_manifest" | cut -f2- -d' ')" 2>/dev/null \
  || {
    echo >&2 "ERROR: ${BASH_SOURCE[0]} cannot find ${f}"
    exit 1
  }
f=
set -e
# --- end runfiles.bash initialization v3 ---

# MARK - Dependencies

fail_sh_location=cgrindel_bazel_starlib/shlib/lib/fail.sh
fail_sh="$(rlocation "${fail_sh_location}")" \
  || (echo >&2 "Failed to locate ${fail_sh_location}" && exit 1)
# shellcheck disable=SC1090
source "${fail_sh}"

# Locate buildozer via runfiles
buildozer_location=buildifier_prebuilt/buildozer/buildozer
buildozer="$(rlocation "${buildozer_location}")" \
  || (echo >&2 "Failed to locate ${buildozer_location}" && exit 1)

# MARK - Default Values

# Default values
dry_run=false
name="bundle"
module_bazel="${BUILD_WORKSPACE_DIRECTORY:-.}/MODULE.bazel"
ruby_version=""

# MARK - Functions

# Read .ruby-version file
read_ruby_version() {
  local version_file="${BUILD_WORKSPACE_DIRECTORY}/.ruby-version"
  if [[ ! -f ${version_file} ]]; then
    fail "Error: .ruby-version not found and --ruby-version not specified"
  fi
  tr -d '[:space:]' <"${version_file}"
}

# Extract minor version from a Ruby version string (e.g., 3.4.8 -> 3.4)
# Ruby uses MAJOR.MINOR.PATCH versioning, and stdgems data is organized by
# minor version since default gems are typically consistent within a minor
# release series.
get_minor_version() {
  local version="$1"
  echo "${version}" | cut -d. -f1,2
}

# MARK - Argument Handling

# Parse arguments
while (("$#")); do
  case "${1}" in
    --dry-run)
      dry_run=true
      shift
      ;;
    --ruby-version)
      ruby_version="${2}"
      shift 2
      ;;
    --name)
      name="${2}"
      shift 2
      ;;
    --module-bazel)
      module_bazel="${2}"
      shift 2
      ;;
    -*)
      fail "Error: Unknown option: ${1}"
      ;;
    *)
      fail "Error: Unexpected argument: ${1}"
      ;;
  esac
done

# Get Ruby version
if [[ -z ${ruby_version} ]]; then
  ruby_version="$(read_ruby_version)"
fi

# Get minor version
minor_version=$(get_minor_version "${ruby_version}")

# MARK - Retrieve stdgems data

# Fetch stdgems data
stdgems_url="${STDGEMS_URL:-https://raw.githubusercontent.com/janlelis/stdgems/main/default_gems.json}"
response=$(curl -sL --max-time 30 "${stdgems_url}")

# Filter for native gems that exist for this Ruby version
# The jq query:
# 1. Select gems where native == true
# 2. Select gems where versions contains the minor version key
# 3. Extract the gem name
# 4. Sort
excluded_gems=$(echo "${response}" | jq -r --arg version "${minor_version}" \
  '.gems[] | select(.native == true) | select(.versions | has($version)) | .gem' \
  | sort)

# Check if we found any gems
if [[ -z ${excluded_gems} ]]; then
  fail <<-EOT
Error: No native gems found for Ruby ${ruby_version} (${minor_version})
This Ruby version may not be supported in stdgems data
EOT
fi

# MARK - Update MODULE.bazel

# Generate output for dry-run or display
output="excluded_gems = [\n"
while IFS= read -r gem; do
  output+="    \"${gem}\",\n"
done <<<"${excluded_gems}"
output+="],"

if [[ ${dry_run} == "true" ]]; then
  # Dry-run: just output the excluded gems
  echo -e "${output}"
  exit 0
fi

# Construct list of gems for buildozer 'add' command
# Convert newline-separated list to space-separated
gem_list=""
while IFS= read -r gem; do
  gem_list+=" ${gem}"
done <<<"${excluded_gems}"

# Update MODULE.bazel using buildozer
buildozer_cmd=(
  "${buildozer}"
  -types ruby.bundle_fetch
  "remove excluded_gems"
  "add excluded_gems${gem_list}"
  "${module_bazel}:${name}"
)
if ! "${buildozer_cmd[@]}" 2>/dev/null; then
  fail <<-EOT
Failed to update ${module_bazel}

Buildozer command failed. This could mean:
- The file doesn't exist at ${module_bazel}
- No ruby.bundle_fetch() call was found with name="${name}"
- The file has syntax errors

You can use --dry-run to see what would be updated:
$(echo -e "${output}")
EOT
fi

echo "Successfully updated excluded_gems in ${module_bazel}"
