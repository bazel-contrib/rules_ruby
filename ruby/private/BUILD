load("@bazel_skylib//:bzl_library.bzl", "bzl_library")

exports_files([
    "binary/binary.cmd.tpl",
    "binary/binary.sh.tpl",
    "gem_build/gem_builder.rb.tpl",
])

exports_files(glob(["**/*.bzl"]))

bzl_library(
    name = "binary",
    srcs = ["binary.bzl"],
    visibility = ["//ruby:__subpackages__"],
    deps = [
        ":library",
        ":providers",
    ],
)

bzl_library(
    name = "gem_build",
    srcs = ["gem_build.bzl"],
    visibility = ["//ruby:__subpackages__"],
    deps = [
        ":library",
        ":providers",
    ],
)

bzl_library(
    name = "gem_push",
    srcs = ["gem_push.bzl"],
    visibility = ["//ruby:__subpackages__"],
    deps = [
        ":binary",
        ":library",
    ],
)

bzl_library(
    name = "library",
    srcs = ["library.bzl"],
    visibility = ["//ruby:__subpackages__"],
    deps = [":providers"],
)

bzl_library(
    name = "test",
    srcs = ["test.bzl"],
    visibility = ["//ruby:__subpackages__"],
    deps = [
        ":binary",
        ":library",
    ],
)

bzl_library(
    name = "toolchain",
    srcs = ["toolchain.bzl"],
    visibility = ["//ruby:__subpackages__"],
    deps = [
        ":download",
        "//ruby/private/toolchain:repository_proxy",
    ],
)

bzl_library(
    name = "bundle",
    srcs = ["bundle.bzl"],
    visibility = ["//ruby:__subpackages__"],
)

bzl_library(
    name = "download",
    srcs = ["download.bzl"],
    visibility = ["//ruby:__subpackages__"],
)

bzl_library(
    name = "providers",
    srcs = ["providers.bzl"],
    visibility = ["//ruby:__subpackages__"],
)
