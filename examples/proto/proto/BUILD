load("@protobuf//bazel:proto_library.bzl", "proto_library")

proto_library(
    name = "foo_proto",
    srcs = ["foo.proto"],
    visibility = ["//visibility:public"],
    deps = [
        ":subdir_proto",
        "@protobuf//:empty_proto",
    ],
)

proto_library(
    name = "subdir_proto",
    srcs = ["subdir/bar.proto"],
    visibility = ["//visibility:public"],
    deps = ["@protobuf//:timestamp_proto"],
)
