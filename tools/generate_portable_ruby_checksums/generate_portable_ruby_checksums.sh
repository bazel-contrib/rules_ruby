#!/usr/bin/env bash

# Generates portable_ruby_checksums for ruby.toolchain() and updates MODULE.bazel or
# ruby/private/portable_ruby_checksums.bzl (when --all is specified).

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
name="ruby"
module_bazel="${BUILD_WORKSPACE_DIRECTORY:-.}/MODULE.bazel"
ruby_version=""
all_releases=false
checksums_bzl="${BUILD_WORKSPACE_DIRECTORY:-.}/ruby/private/portable_ruby_checksums.bzl"

# jdx/ruby platform names (order matches portable_ruby_checksums.bzl)
PLATFORMS=("x86_64_linux" "macos" "arm64_linux")

# MARK - Functions

# Read .ruby-version file
read_ruby_version() {
  local version_file="${BUILD_WORKSPACE_DIRECTORY}/.ruby-version"
  if [[ ! -f ${version_file} ]]; then
    fail "Error: .ruby-version not found and --ruby-version not specified"
  fi
  tr -d '[:space:]' <"${version_file}"
}

# MARK - Argument Handling

# Parse arguments
args=()
while (("$#")); do
  case "${1}" in
    --dry-run)
      dry_run=true
      shift
      ;;
    --all)
      all_releases=true
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
    --checksums-bzl)
      checksums_bzl="${2}"
      shift 2
      ;;
    -*)
      fail "Error: Unknown option: ${1}"
      ;;
    *)
      args+=("${1}")
      shift
      ;;
  esac
done

# MARK - --all mode: update ruby/private/portable_ruby_checksums.bzl

if [[ ${all_releases} == "true" ]]; then
  # Verify we are running inside the rules_ruby repo
  workspace_module_bazel="${BUILD_WORKSPACE_DIRECTORY:-.}/MODULE.bazel"
  if ! grep -q 'name = "rules_ruby"' "${workspace_module_bazel}" 2>/dev/null; then
    fail "Error: --all is only supported when run inside the rules_ruby repository"
  fi

  # Fetch list of all releases with their assets
  list_url="${RV_RUBY_LIST_API_URL:-https://api.github.com/repos/jdx/ruby/releases?per_page=100}"
  all_response=$(curl -sL --max-time 60 "${list_url}")

  # Extract all checksums (excluding no_yjit), sorted by key in reverse order
  entries=$(echo "${all_response}" | jq -r \
    '[.[].assets[] | select(.name | endswith(".tar.gz")) | select(.name | contains("no_yjit") | not) | {(.name): (.digest | ltrimstr("sha256:"))}] | add | to_entries | sort_by(.key) | reverse | .[] | "    \"\(.key)\": \"\(.value)\","')

  if [[ -z ${entries} ]]; then
    fail "Error: No checksums found in releases response"
  fi

  # Build the bzl file content
  bzl_content='"Provides checksums for portable Ruby versions from jdx/ruby."

# Generated via:
# bazel run //tools/generate_portable_ruby_checksums -- --all

PORTABLE_RUBY_CHECKSUMS = {
'"${entries}"'
}
'

  if [[ ${dry_run} == "true" ]]; then
    printf "%s" "${bzl_content}"
    exit 0
  fi

  printf "%s" "${bzl_content}" >"${checksums_bzl}"
  echo "Successfully updated ${checksums_bzl}"
  exit 0
fi

# MARK - Single-version mode

# Get Ruby version
if [[ -z ${ruby_version} ]]; then
  ruby_version="$(read_ruby_version)"
fi

# MARK - Retrieve jdx/ruby release info

# Fetch release data from GitHub API
api_url="${RV_RUBY_API_URL:-https://api.github.com/repos/jdx/ruby/releases/tags}/${ruby_version}"
response=$(curl -sL --max-time 30 "${api_url}")

# Check if release was found
if echo "${response}" | jq -e '.message == "Not Found"' >/dev/null 2>&1; then
  fail "Error: jdx/ruby release for Ruby ${ruby_version} not found"
fi

# MARK - Extract checksums

# Extract checksums for each platform
declare -A checksums
found_ruby_version=false

for platform in "${PLATFORMS[@]}"; do
  # Find asset for this Ruby version and platform
  asset_name="ruby-${ruby_version}.${platform}.tar.gz"
  digest=$(echo "${response}" | jq -r --arg name "${asset_name}" \
    '.assets[] | select(.name == $name) | .digest // ""')

  if [[ -n ${digest} ]]; then
    found_ruby_version=true
    # Strip "sha256:" prefix if present
    checksum="${digest#sha256:}"
    checksums["${platform}"]="${checksum}"
  fi
done

# Check if we found any assets for this Ruby version
if [[ ${found_ruby_version} != "true" ]]; then
  fail <<-EOT
Error: Ruby version ${ruby_version} not found in jdx/ruby releases
EOT
fi

# Check if we have all expected platforms
missing_platforms=()
for platform in "${PLATFORMS[@]}"; do
  if [[ -z ${checksums[${platform}]:-} ]]; then
    missing_platforms+=("${platform}")
  fi
done

if [[ ${#missing_platforms[@]} -gt 0 ]]; then
  warn "Warning: Missing platforms in release: ${missing_platforms[*]}"
fi

# MARK - Update MODULE.bazel

# Generate output for dry-run or display
output="portable_ruby_checksums = {\n"
for platform in "${PLATFORMS[@]}"; do
  if [[ -n ${checksums[${platform}]:-} ]]; then
    output+="    \"ruby-${ruby_version}.${platform}.tar.gz\": \"${checksums[${platform}]}\",\n"
  fi
done
output+="},"

if [[ ${dry_run} == "true" ]]; then
  # Dry-run: just output the checksums
  echo -e "${output}"
  exit 0
fi

# Construct dict string for buildozer
dict_str=""
for platform in "${PLATFORMS[@]}"; do
  if [[ -n ${checksums[${platform}]:-} ]]; then
    dict_str+=" ruby-${ruby_version}.${platform}.tar.gz:${checksums[${platform}]}"
  fi
done

# Update MODULE.bazel using buildozer
# Set portable_ruby and portable_ruby_checksums
buildozer_cmd=(
  "${buildozer}"
  -types ruby.toolchain
  "set portable_ruby True"
  "remove portable_ruby_checksums"
  "dict_set portable_ruby_checksums ${dict_str}"
  "${module_bazel}:${name}"
)
if ! "${buildozer_cmd[@]}" 2>/dev/null; then
  fail <<-EOT
Failed to update ${module_bazel}

Buildozer command failed. This could mean:
- The file doesn't exist at ${module_bazel}
- No ruby.toolchain() call was found with name="${name}"
- The file has syntax errors

You can use --dry-run to see what would be updated:
$(echo -e "${output}")
EOT
fi

echo "Successfully updated portable_ruby and portable_ruby_checksums in ${module_bazel}"
