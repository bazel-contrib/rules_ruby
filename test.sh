#!/bin/sh

cd examples/gem || exit 1
bazel build :gem || exit 1
bazel run lib/gem:print-version || exit 1
bazel run :rubocop || exit 1
bazel test spec:all || exit 1
