load("@bazel_skylib//:bzl_library.bzl", "bzl_library")
load("@io_bazel_stardoc//stardoc:stardoc.bzl", "stardoc")

bzl_library(
    name = "rules",
    srcs = [
        "//ruby:defs.bzl",
        "//ruby:deps.bzl",
        "//ruby:toolchain.bzl",
        "//ruby/private:binary.bzl",
        "//ruby/private:bundle.bzl",
        "//ruby/private:download.bzl",
        "//ruby/private:gem_build.bzl",
        "//ruby/private:gem_push.bzl",
        "//ruby/private:library.bzl",
        "//ruby/private:providers.bzl",
        "//ruby/private:test.bzl",
    ],
)

stardoc(
    name = "stardoc",
    out = "README.md",
    input = "//ruby:defs.bzl",
    deps = [":rules"],
)
