load("@bazel_skylib//:bzl_library.bzl", "bzl_library")
load("@bazel_skylib//rules:common_settings.bzl", "bool_flag")

package(default_visibility = ["//visibility:public"])

bool_flag(
    name = "compile_bytecode",
    build_setting_default = False,
)

config_setting(
    name = "bytecode_enabled",
    flag_values = {":compile_bytecode": "True"},
)

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
    name = "toolchain",
    srcs = ["toolchain.bzl"],
)
