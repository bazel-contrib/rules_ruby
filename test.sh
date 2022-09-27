#!/bin/sh

cd examples/gem || exit 1

# rb_library
bazel build :gem || exit 1

# rb_binary
bazel run lib/gem:print-version || exit 1
bazel run :rubocop || exit 1

# rb_test
bazel test spec:all || exit 1

# rb_gem
bazel build :example || exit
