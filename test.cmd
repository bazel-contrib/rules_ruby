cd examples/gem || exit /b

bazel build ... || exit /b
bazel run lib/gem:add-numbers 2 || exit /b
bazel run lib/gem:print-version || exit /b
bazel run :rubocop || exit /b
bazel test spec/... || exit /b
