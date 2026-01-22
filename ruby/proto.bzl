"User-facing public API for registering Ruby gRPC protoc plugin toolchains."

load("//ruby/private:proto.bzl", "GRPC_PLUGIN_TOOLCHAIN", "ruby_grpc_protoc_plugin_toolchain")

def rb_grpc_protoc_plugin_toolchain(name, grpc_plugin):
    concrete_target = name + ".concrete"

    ruby_grpc_protoc_plugin_toolchain(
        name = concrete_target,
        grpc_plugin = grpc_plugin,
    )

    native.toolchain(
        name = name,
        toolchain_type = GRPC_PLUGIN_TOOLCHAIN,
        visibility = ["//visibility:public"],
        toolchain = concrete_target,
    )
