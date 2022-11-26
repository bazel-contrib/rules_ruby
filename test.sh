#!/bin/sh -x

cd examples/gem || exit 1

bazel build ... || exit 1
bazel run lib/gem:add-numbers 2 || exit 1
bazel run lib/gem:print-version || exit 1
bazel run :rubocop || exit 1
bazel test spec/... || exit 1
