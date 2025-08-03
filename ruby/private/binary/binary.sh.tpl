#!/usr/bin/env bash

{rlocation_function}

warn() {
  if [[ "${#}" -gt 0 ]]; then
    echo >&2 "${@}"
  else
    cat >&2
  fi
}

# shellcheck disable=SC2120
fail() {
  local cmd=(warn)
  if [[ "${#}" -gt 0 ]]; then
    cmd+=("${@}")
  fi
  "${cmd[@]}"
  exit 1
}

# Provide a realpath implementation for macOS.
realpath() (
  OURPWD=$PWD
  cd "$(dirname "$1")"
  LINK=$(readlink "$(basename "$1")")
  while [ "$LINK" ]; do
    cd "$(dirname "$LINK")"
    LINK=$(readlink "$(basename "$1")")
  done
  REALPATH="$PWD/$(basename "$1")"
  cd "$OURPWD"
  echo "$REALPATH"
)

export RUNFILES_DIR="$(realpath "${RUNFILES_DIR:-$0.runfiles}")"

# Find location of Ruby in runfiles.
export PATH=$(dirname $(rlocation {ruby})):$PATH

# Find location of JAVA_HOME in runfiles.
if [ -n "{java_bin}" ]; then
  export JAVA_HOME=$(dirname $(dirname $(rlocation "{java_bin}")))
fi

# Bundler expects the $HOME directory to be writable and produces misleading
# warnings if it isn't. This isn't the case in every situation (e.g. remote
# execution) and Bazel recommends using $TEST_TMPDIR when it's available:
# https://bazel.build/reference/test-encyclopedia#initial-conditions
#
# We set $HOME prior to setting environment variables from the target itself so
# that users can override this behavior if they desire.
if [ -n "${TEST_TMPDIR:-}" ]; then
  export HOME=$TEST_TMPDIR
fi

# Set environment variables.
{env}

# Find location of Bundle path in runfiles.
if [ -n "{bundler_command}" ]; then
  export BUNDLE_GEMFILE=$(rlocation $BUNDLE_GEMFILE)
  export BUNDLE_PATH=$(rlocation $BUNDLE_PATH)
fi

if [ -n "{locate_binary_in_runfiles}" ]; then
  binary="$(rlocation "{binary}")" \
    || (fail "Failed to locate {binary} in the runfiles." \
      "Did you forget to add the binary to the deps?")
else
  binary="{binary}"
fi

exec {bundler_command} {ruby_binary_name} $binary {args} "$@"

# vim: ft=bash
