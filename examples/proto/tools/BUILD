load("@rules_ruby//ruby:defs.bzl", "rb_binary")

package(default_visibility = ["//visibility:public"])

rb_binary(
    name = "grpc_tools_ruby_protoc_plugin",
    main = "@bundle//bin:grpc_tools_ruby_protoc_plugin",
    deps = ["@bundle"],
)
