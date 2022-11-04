load("@bazel_skylib//:bzl_library.bzl", "bzl_library")
load("@io_bazel_stardoc//stardoc:stardoc.bzl", "stardoc")

stardoc(
    name = "stardoc",
    input = "//ruby:defs.bzl",
    out = "README.md",
    deps = ["//ruby:rules"]
)

toolchain_type(
    name = "toolchain_type",
    visibility = ["//visibility:public"],
)

