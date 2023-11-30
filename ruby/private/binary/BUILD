load("@bazel_skylib//:bzl_library.bzl", "bzl_library")

exports_files(glob(["*.tpl"]))

bzl_library(
    name = "rlocation",
    srcs = ["rlocation.bzl"],
    visibility = ["//ruby:__subpackages__"],
)
