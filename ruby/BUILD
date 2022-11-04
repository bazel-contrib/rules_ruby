load("@bazel_skylib//:bzl_library.bzl", "bzl_library")

exports_files(["defs.bzl"])

bzl_library(
    name = "rules",
    srcs = glob(["*.bzl"]),
    deps = ["//ruby/private:rules"],
    visibility = ["//visibility:public"],
)
