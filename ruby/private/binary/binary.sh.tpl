#!/usr/bin/env bash

# Find location of JAVA_HOME in runfiles.
if [ -n "{java_bin}" ]; then
  {rlocation_function}
  export JAVA_HOME=$(dirname $(dirname $(rlocation "{java_bin}")))
fi

# Set environment variables.
export PATH={toolchain_bindir}:$PATH
{env}

{bundler_command} {ruby_binary_name} {binary} {args} $@
