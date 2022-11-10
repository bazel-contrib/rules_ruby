load("@bazel_skylib//:bzl_library.bzl", "bzl_library")

package(default_visibility = ["//:__subpackages__"])

bzl_library(
    name = "ruby",
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
