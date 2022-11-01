load("@rules_ruby//ruby:defs.bzl", "rb_library", "rb_test")

rb_library(
    name = "spec_helper",
    srcs = ["spec_helper.rb"],
    deps = [
        "//:gem",
        "@bundle"
    ],
)

rb_test(
    name = "add",
    bin = "@bundle//:bin/rspec",
    args = ["spec/add_spec.rb"],
    srcs = ["add_spec.rb"],
    deps = [":spec_helper"]
)

rb_test(
    name = "subtract",
    bin = "@bundle//:bin/rspec",
    args = ["spec/subtract_spec.rb"],
    srcs = ["subtract_spec.rb"],
    deps = [":spec_helper"]
)
