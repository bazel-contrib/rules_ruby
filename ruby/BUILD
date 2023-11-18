load("@bazel_skylib//:bzl_library.bzl", "bzl_library")

package(default_visibility = ["//visibility:public"])

exports_files(glob(["*.bzl"]))

toolchain_type(
    name = "toolchain_type",
    visibility = ["//visibility:public"],
)

bzl_library(
    name = "defs",
    srcs = ["defs.bzl"],
    deps = [
        "//ruby/private:binary",
        "//ruby/private:gem_build",
        "//ruby/private:gem_push",
        "//ruby/private:library",
        "//ruby/private:test",
    ],
)

bzl_library(
    name = "deps",
    srcs = ["deps.bzl"],
    deps = [
        "//ruby/private:bundle",
        "//ruby/private:download",
    ],
)

bzl_library(
    name = "toolchain",
    srcs = ["toolchain.bzl"],
)
