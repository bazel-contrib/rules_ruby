#!/usr/bin/env bash

export PATH={toolchain_bindir}:$PATH
{ruby_binary_name} {binary} {args} $@
