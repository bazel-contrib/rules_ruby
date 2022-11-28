#!/usr/bin/env bash

export PATH={toolchain_bindir}:$PATH
ruby {binary} {args} $@
