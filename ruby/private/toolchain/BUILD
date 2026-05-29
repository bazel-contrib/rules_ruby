load("@bazel_skylib//:bzl_library.bzl", "bzl_library")

bzl_library(
    name = "platforms",
    srcs = ["platforms.bzl"],
    visibility = ["//ruby:__subpackages__"],
)

bzl_library(
    name = "hub",
    srcs = ["hub.bzl"],
    visibility = ["//ruby:__subpackages__"],
    deps = [":platforms"],
)

bzl_library(
    name = "repository_proxy",
    srcs = ["repository_proxy.bzl"],
    visibility = ["//ruby:__subpackages__"],
    deps = [":platforms"],
)
