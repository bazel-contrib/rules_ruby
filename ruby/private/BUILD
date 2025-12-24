load("@bazel_skylib//:bzl_library.bzl", "bzl_library")

bzl_library(
    name = "binary",
    srcs = ["binary.bzl"],
    visibility = ["//ruby:__subpackages__"],
    deps = [
        ":compile",
        ":library",
        ":providers",
        ":utils",
        "@bazel_skylib//rules:common_settings",
    ],
)

bzl_library(
    name = "gem_build",
    srcs = ["gem_build.bzl"],
    visibility = ["//ruby:__subpackages__"],
    deps = [
        ":library",
        ":providers",
        ":utils",
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
    name = "compile",
    srcs = ["compile.bzl"],
    visibility = ["//ruby:__subpackages__"],
    deps = [":utils"],
)

bzl_library(
    name = "library",
    srcs = ["library.bzl"],
    visibility = ["//ruby:__subpackages__"],
    deps = [
        ":compile",
        ":providers",
        "@bazel_skylib//rules:common_settings",
    ],
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
    name = "bundler_checksums",
    srcs = ["bundler_checksums.bzl"],
    visibility = ["//ruby:__subpackages__"],
)

bzl_library(
    name = "bundle_fetch",
    srcs = ["bundle_fetch.bzl"],
    visibility = ["//ruby:__subpackages__"],
    deps = [
        ":bundler_checksums",
        ":utils",
        "//ruby/private/bundle_fetch:gemfile_lock_parser",
        "@bazel_skylib//lib:paths",
        "@bazel_skylib//lib:versions",
        "@bazel_tools//tools/build_defs/repo:utils.bzl",
    ],
)

bzl_library(
    name = "bundle_install",
    srcs = ["bundle_install.bzl"],
    visibility = ["//ruby:__subpackages__"],
    deps = [
        ":bundle_fetch",
        ":gem_install",
        ":providers",
        ":utils",
    ],
)

bzl_library(
    name = "gem",
    srcs = ["gem.bzl"],
    visibility = ["//ruby:__subpackages__"],
    deps = [":providers"],
)

bzl_library(
    name = "gem_install",
    srcs = ["gem_install.bzl"],
    visibility = ["//ruby:__subpackages__"],
    deps = [
        ":providers",
        ":utils",
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

bzl_library(
    name = "utils",
    srcs = ["utils.bzl"],
    visibility = ["//ruby:__subpackages__"],
)
