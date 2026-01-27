load("@rules_ruby//ruby:defs.bzl", "rb_binary", "rb_test")

# A simple binary that uses the Git-sourced hello_world gem
rb_binary(
    name = "greeter",
    srcs = ["greeter.rb"],
    deps = ["@bundle"],
)

# Test that verifies the Git-sourced gem works correctly
rb_test(
    name = "greeter_test",
    srcs = ["greeter_test.rb"],
    deps = ["@bundle"],
)
