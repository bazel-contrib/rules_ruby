#!/usr/bin/env bash

export PATH={toolchain_bindir}:$PATH
{bundler_command} {ruby_binary_name} {binary} {args} $@
