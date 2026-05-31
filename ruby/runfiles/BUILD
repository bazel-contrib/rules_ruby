load("//ruby:defs.bzl", "rb_library", "rb_test")

exports_files(["lib/bazel/runfiles.rb"])

rb_library(
    name = "runfiles",
    srcs = ["lib/bazel/runfiles.rb"],
    visibility = ["//visibility:public"],
)

rb_test(
    name = "runfiles_test",
    size = "small",
    srcs = ["runfiles_test.rb"],
    tags = ["manual"],
)
