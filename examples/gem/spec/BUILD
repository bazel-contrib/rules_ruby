load("@rules_ruby//ruby:defs.bzl", "rb_library", "rb_test")

rb_library(
    name = "spec_helper",
    srcs = ["spec_helper.rb"],
    deps = [
        "//:gem",
        "@bundle",
    ],
)

rb_test(
    name = "add",
    srcs = ["add_spec.rb"],
    args = ["spec/add_spec.rb"],
    bin = "@bundle//:bin/rspec",
    deps = [":spec_helper"],
)

rb_test(
    name = "subtract",
    srcs = ["subtract_spec.rb"],
    args = ["spec/subtract_spec.rb"],
    bin = "@bundle//:bin/rspec",
    deps = [":spec_helper"],
)
