#!/bin/sh

cd examples/gem || exit 1
bazel build :gem
bazel run lib/gem:print-version
bazel run :rubocop
