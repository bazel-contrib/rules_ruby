load("@bazel_skylib//:bzl_library.bzl", "bzl_library")

package(default_visibility = ["//visibility:public"])

exports_files(glob(["*.bzl"]))

toolchain_type(
    name = "toolchain_type",
    visibility = ["//visibility:public"],
)

toolchain_type(
    name = "ruby_grpc_protoc_plugin.toolchain_type",
    visibility = ["//visibility:public"],
)

bzl_library(
    name = "defs",
    srcs = ["defs.bzl"],
    deps = [
        "//ruby/private:binary",
        "//ruby/private:bundle_install",
        "//ruby/private:gem",
        "//ruby/private:gem_build",
        "//ruby/private:gem_install",
        "//ruby/private:gem_push",
        "//ruby/private:library",
        "//ruby/private:test",
    ],
)

starlark_doc_extract(
    name = "defs.doc_extract",
    src = "defs.bzl",
    deps = [":defs"],
)

bzl_library(
    name = "deps",
    srcs = ["deps.bzl"],
    deps = [
        "//ruby/private:bundle",
        "//ruby/private:bundle_fetch",
        "//ruby/private:toolchain",
    ],
)

starlark_doc_extract(
    name = "deps.doc_extract",
    src = "deps.bzl",
    deps = [":deps"],
)

bzl_library(
    name = "extensions",
    srcs = ["extensions.bzl"],
    deps = [
        ":deps",
        "//ruby/private:download",
        "//ruby/private:toolchain",
    ],
)

bzl_library(
    name = "proto",
    srcs = ["proto.bzl"],
    deps = [
        "//ruby/private:proto",
        "@protobuf//bazel/toolchains:proto_lang_toolchain_bzl",
    ],
)

bzl_library(
    name = "toolchain",
    srcs = ["toolchain.bzl"],
)
