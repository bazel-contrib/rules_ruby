"User-facing public API for registering Ruby gRPC protoc plugin toolchains."

load("@protobuf//bazel/toolchains:proto_lang_toolchain.bzl", "proto_lang_toolchain")
load("//ruby/private:proto.bzl", "GRPC_PLUGIN_TOOLCHAIN")

def rb_grpc_protoc_plugin_toolchain(name, grpc_plugin):
    """Declare a toolchain for the Ruby gRPC protoc plugin.

    NB: the toolchain produced by this macro is actually named [name]_toolchain, so THAT is what you must register.
    Even better, make a dedicated 'toolchains' directory and put all your toolchains in there, then register them all with 'register_toolchains("//path/to/toolchains:all")'.
    """
    proto_lang_toolchain(
        name = name,
        plugin = grpc_plugin,
        toolchain_type = GRPC_PLUGIN_TOOLCHAIN,
        command_line = "ignored by rules_ruby",
    )
