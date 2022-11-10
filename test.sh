#!/bin/sh -x

cd examples/gem || exit 1

# rb_library
bazel build :gem || exit 1

# rb_binary
bazel run lib/gem:print-version || exit 1
bazel run :rubocop || exit 1

# rb_test
bazel test spec:all || exit 1

# rb_gem_build
bazel build :gem-build || exit 1
