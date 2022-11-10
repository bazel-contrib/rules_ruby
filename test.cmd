cd examples/gem

:: rb_library
bazel build :gem || exit /b

:: rb_binary
bazel run lib/gem:print-version || exit /b
bazel run :rubocop || exit /b

:: rb_test
bazel test spec:all || exit /b

:: rb_gem_build
bazel build :gem-build || exit /b
