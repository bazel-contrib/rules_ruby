"""Ruby proto generation aspect for rules_ruby.

This file is loaded by `rules_ruby` (see its `rb_library` implementation) using
`@@//proto:ruby.bzl`, so it must remain in this workspace at `proto/ruby.bzl`.
"""

load("@protobuf//bazel/common:proto_info.bzl", "ProtoInfo")
load("//ruby/private:providers.bzl", "RubyFilesInfo")

GRPC_PLUGIN_TOOLCHAIN = "@rules_ruby//ruby:ruby_grpc_protoc_plugin.toolchain_type"
PROTO_TOOLCHAIN = "@protobuf//bazel/private:proto_toolchain_type"
RUBY_OUTPUT_FILE = "{proto_file_basename}_pb.rb"
RUBY_SERVICE_OUTPUT_FILE = "{proto_file_basename}_services_pb.rb"

def _ruby_proto_aspect_impl(target, ctx):
    if not ProtoInfo in target:
        return []

    proto_info = ctx.toolchains[PROTO_TOOLCHAIN].proto
    grpc_info = ctx.toolchains[GRPC_PLUGIN_TOOLCHAIN].proto
    proto_srcs = target[ProtoInfo].direct_sources
    proto_deps = target[ProtoInfo].transitive_sources
    outputs = []
    for src in proto_srcs:
        proto_file_basename = src.basename.replace(".proto", "")
        msg_output = ctx.actions.declare_file(RUBY_OUTPUT_FILE.format(proto_file_basename = proto_file_basename))
        service_output = ctx.actions.declare_file(RUBY_SERVICE_OUTPUT_FILE.format(proto_file_basename = proto_file_basename))

        # FIXME: Use Bazel 9 feature to have a dynamic dependency graph based on file contents.
        # We can peek into the .proto file and produce a directory that has some indicator of whether services were found.
        # Then ctx.actions.map_directory lets us stamp out new actions during execution.
        services_not_created_workaround = ">{service_output} echo '# No Services'".format(service_output = service_output.path)

        ctx.actions.run_shell(
            # https://grpc.io/docs/languages/ruby/basics/#generating-client-and-server-code
            # grpc_tools_ruby_protoc -I ../../protos --ruby_out=../lib --grpc_out=../lib ../../protos/route_guide.proto
            command = " && ".join([
                services_not_created_workaround,
                "{protoc} --plugin=protoc-gen-grpc={grpc} --ruby_out={bindir} --grpc_out={bindir} {sources}".format(
                    protoc = proto_info.proto_compiler.executable.path,
                    sources = " ".join([p.path for p in proto_srcs]),
                    grpc = grpc_info.plugin.executable.path,
                    bindir = ctx.bin_dir.path,
                    service_output = service_output.path,
                ),
            ]),
            tools = [grpc_info.plugin, proto_info.proto_compiler],
            inputs = depset(proto_srcs, transitive = [proto_deps]),
            outputs = [msg_output, service_output],
        )
        outputs.append(msg_output)
        outputs.append(service_output)
    return [
        RubyFilesInfo(
            transitive_srcs = depset(outputs),
            transitive_deps = depset(),
            transitive_data = depset(),
            bundle_env = {},
        ),
    ]

# Walk the graph of "deps" and find any that provide ProtoInfo. Augment those targets with RubyFilesInfo.
ruby_proto_aspect = aspect(
    implementation = _ruby_proto_aspect_impl,
    attr_aspects = ["deps"],
    required_providers = [ProtoInfo],
    provides = [RubyFilesInfo],
    toolchains = [PROTO_TOOLCHAIN, GRPC_PLUGIN_TOOLCHAIN],
)
