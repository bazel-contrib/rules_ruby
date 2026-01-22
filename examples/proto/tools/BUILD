load("@rules_ruby//ruby:defs.bzl", "rb_binary")
load("@rules_ruby//ruby:proto.bzl", "rb_grpc_protoc_plugin_toolchain")

rb_binary(
    name = "grpc_tools_ruby_protoc_plugin",
    main = "@bundle//bin:grpc_tools_ruby_protoc_plugin",
    deps = ["@bundle"],
)

rb_grpc_protoc_plugin_toolchain(
    name = "grpc_protoc_plugin",
    grpc_plugin = ":grpc_tools_ruby_protoc_plugin",
)
