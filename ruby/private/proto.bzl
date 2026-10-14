"""Ruby proto generation aspect for rules_ruby.

This file is loaded by `rules_ruby` (see its `rb_library` implementation) using
`@@//proto:ruby.bzl`, so it must remain in this workspace at `proto/ruby.bzl`.
"""

load("@protobuf//bazel/common:proto_info.bzl", "ProtoInfo")
load("//ruby/private:providers.bzl", "RubyFilesInfo", "get_transitive_load_paths")
load(":proto_common.bzl", "proto_common")

GRPC_PLUGIN_TOOLCHAIN = "@rules_ruby//ruby:ruby_grpc_protoc_plugin.toolchain_type"
PROTO_TOOLCHAIN = "@protobuf//bazel/private:proto_toolchain_type"
RUBY_OUTPUT_FILE = "{proto_file_basename}_pb.rb"
RUBY_SERVICE_OUTPUT_FILE = "{proto_file_basename}_services_pb.rb"

# The google-protobuf gem already ships Ruby code for these, and generating our
# own copies would shadow the gem's on the load path.
PROTOBUF_WELL_KNOWN_TYPES_REPO = Label("@protobuf//:BUILD").repo_name

def _ruby_files_info(ctx, srcs = [], load_paths = []):
    deps = ctx.rule.attr.deps
    return RubyFilesInfo(
        transitive_srcs = depset(srcs, transitive = [
            dep[RubyFilesInfo].transitive_srcs
            for dep in deps
            if RubyFilesInfo in dep
        ]),
        transitive_load_paths = get_transitive_load_paths(load_paths, deps),
        transitive_deps = depset(),
        transitive_data = depset(),
    )

def _runfiles_load_path(ctx, output_root, proto_outdir):
    """Converts a protoc output directory into a path relative to the runfiles root."""
    path = proto_outdir.removeprefix(output_root.path).removeprefix("/")
    if path.startswith("external/"):
        return path.removeprefix("external/")
    if path.startswith("../"):
        return path.removeprefix("../")
    return ctx.workspace_name + "/" + path if path else ctx.workspace_name

def _ruby_proto_aspect_impl(target, ctx):
    if not ProtoInfo in target:
        return []

    proto_info = target[ProtoInfo]

    # Aggregator proto_library targets (deps only, no srcs) have nothing to compile.
    is_aggregator = not proto_info.direct_sources
    if is_aggregator or target.label.repo_name == PROTOBUF_WELL_KNOWN_TYPES_REPO:
        return [_ruby_files_info(ctx)]

    protoc_info = ctx.exec_groups["proto"].toolchains[PROTO_TOOLCHAIN].proto
    grpc_info = ctx.exec_groups["proto"].toolchains[GRPC_PLUGIN_TOOLCHAIN].proto
    msg_outputs = proto_common.declare_generated_files(ctx.actions, proto_info, "_pb.rb")
    service_outputs = proto_common.declare_generated_files(ctx.actions, proto_info, "_services_pb.rb")
    proto_outdir = proto_common.output_directory(proto_info, msg_outputs[0].root)

    # FIXME: Use Bazel 9 feature to have a dynamic dependency graph based on file contents.
    # We can peek into the .proto file and produce a directory that has some indicator of whether services were found.
    # Then ctx.actions.map_directory lets us stamp out new actions during execution.
    services_not_created_workarounds = [
        ">{service_output} echo '# No Services'".format(service_output = out.path)
        for out in service_outputs
    ]

    args = ctx.actions.args()
    args.add_joined("--descriptor_set_in", proto_info.transitive_descriptor_sets, join_with = ctx.configuration.host_path_separator)
    args.add_joined(["--plugin", "protoc-gen-grpc", grpc_info.plugin.executable.path], join_with = "=")
    args.add_joined(["--ruby_out", proto_outdir], join_with = "=")
    args.add_joined(["--grpc_out", proto_outdir], join_with = "=")

    # Vendored: https://github.com/protocolbuffers/protobuf/blob/v31.1/bazel/common/proto_common.bzl#L193-L204
    # Protoc searches for .protos -I paths in order they are given and then
    # uses the path within the directory as the package.
    # This requires ordering the paths from most specific (longest) to least
    # specific ones, so that no path in the list is a prefix of any of the
    # following paths in the list.
    # For example: 'bazel-out/k8-fastbuild/bin/external/foo' needs to be listed
    # before 'bazel-out/k8-fastbuild/bin'. If not, protoc will discover file under
    # the shorter path and use 'external/foo/...' as its package path.
    args.add_all(proto_info.transitive_proto_path, map_each = proto_common.import_virtual_proto_path)
    args.add_all(proto_info.transitive_proto_path, map_each = proto_common.import_repo_proto_path)
    args.add_all(proto_info.transitive_proto_path, map_each = proto_common.import_main_output_proto_path)
    args.add("-I.")  # Needs to come last
    args.add_all(proto_info.direct_sources)
    ctx.actions.run_shell(
        exec_group = "proto",
        # https://grpc.io/docs/languages/ruby/basics/#generating-client-and-server-code
        # grpc_tools_ruby_protoc -I ../../protos --ruby_out=../lib --grpc_out=../lib ../../protos/route_guide.proto
        command = " && ".join(services_not_created_workarounds + ["{} $@".format(protoc_info.proto_compiler.executable.path)]),
        tools = [grpc_info.plugin, protoc_info.proto_compiler],
        inputs = depset(proto_info.direct_sources, transitive = [proto_info.transitive_descriptor_sets]),
        outputs = msg_outputs + service_outputs,
        arguments = [args],
    )

    return [
        _ruby_files_info(
            ctx,
            srcs = msg_outputs + service_outputs,
            load_paths = [_runfiles_load_path(ctx, msg_outputs[0].root, proto_outdir)],
        ),
    ]

# Walk the graph of "deps" and find any that provide ProtoInfo. Augment those targets with RubyFilesInfo.
ruby_proto_aspect = aspect(
    implementation = _ruby_proto_aspect_impl,
    attr_aspects = ["deps"],
    required_providers = [ProtoInfo],
    provides = [RubyFilesInfo],
    # Protoc invokes the gRPC plugin, so both must run on the same platform.
    exec_groups = {
        "proto": exec_group(toolchains = [PROTO_TOOLCHAIN, GRPC_PLUGIN_TOOLCHAIN]),
    },
)
