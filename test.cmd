cd examples/gem

bazel build ... || exit /b
bazel run lib/gem:print-version || exit /b
bazel run :rubocop || exit /b
bazel test spec/... || exit /b
