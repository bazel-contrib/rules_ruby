load("@bazel_skylib//:bzl_library.bzl", "bzl_library")

exports_files(["gem/gem_builder.rb.tpl"])

bzl_library(
    name = "rules",
    srcs = glob(["**/*.bzl"]),
    visibility = ["//visibility:public"],
)
