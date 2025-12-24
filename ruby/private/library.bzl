"Implementation details for rb_library"

load("@bazel_skylib//rules:common_settings.bzl", "BuildSettingInfo")
load("//ruby/private:compile.bzl", "compile_ruby_sources")
load(
    "//ruby/private:providers.bzl",
    "BundlerInfo",
    "RubyBytecodeInfo",
    "RubyFilesInfo",
    "get_bundle_env",
    "get_transitive_data",
    "get_transitive_deps",
    "get_transitive_runfiles",
    "get_transitive_srcs",
)

ATTRS = {
    "srcs": attr.label_list(
        allow_files = [".rb", ".gemspec", "Gemfile", "Gemfile.lock"],
        doc = "List of Ruby source files used to build the library.",
    ),
    "deps": attr.label_list(
        doc = "List of other Ruby libraries the target depends on.",
    ),
    "data": attr.label_list(
        allow_files = True,
        doc = "List of runtime dependencies needed by a program that depends on this library.",
    ),
    "bundle_env": attr.string_dict(
        default = {},
        doc = "List of bundle environment variables to set when building the library.",
    ),
    "_compile_bytecode": attr.label(
        default = "@rules_ruby//ruby:compile_bytecode",
        providers = [BuildSettingInfo],
    ),
    "_compile_script": attr.label(
        allow_single_file = True,
        default = "@rules_ruby//ruby/private/compile",
    ),
}

def _new_bytecode_info(bytecode_files = [], provider = None):
    """Creat a bytecode info struct.

    Args:
        bytecode_files: Optional. A `list` of `File` objects.
        provider: Optional. A `RubyBytecodeInfo` provider instance.

    Returns:
        A `struct`.
    """
    return struct(
        bytecode_files = bytecode_files,
        provider = provider,
    )

def _compile_to_bytecode_noop(_):
    """A noop implementation for compile_to_bytecode.

    Returns:
        A default bytecode info struct.
    """
    return _new_bytecode_info()

def _compile_to_bytecode(ctx):
    """A compile_to_bytecode implementation that defines actions that compile \
    Ruby source files to bytecode.

    Args:
        ctx: A `ctx`.

    Returns:
        A bytecode info struct.
    """
    if not ctx.attr._compile_bytecode[BuildSettingInfo].value:
        return _new_bytecode_info()

    # Get the Ruby toolchain
    toolchain = ctx.toolchains["@rules_ruby//ruby:toolchain_type"]

    # Compile this rule's direct sources
    direct_mappings = compile_ruby_sources(
        ctx,
        ctx.files.srcs,
        toolchain,
        ctx.file._compile_script,
    )

    # Collect transitive mappings from deps
    transitive_mappings = {}
    for dep in ctx.attr.deps:
        if not RubyBytecodeInfo in dep:
            continue
        transitive_mappings.update(dep[RubyBytecodeInfo].transitive_mappings)

    # Merge direct and transitive mappings
    transitive_mappings.update(direct_mappings)

    return _new_bytecode_info(
        bytecode_files = direct_mappings.values(),
        provider = RubyBytecodeInfo(
            mappings = direct_mappings,
            transitive_mappings = transitive_mappings,
        ),
    )

def _rb_library_impl_factory(compile_to_bytecode):
    """Provide an rb_library implementation with a custom compile_to_bytecode.

    Args:
        compile_to_bytecode: A function for defining actions to compile Ruby
            source to bytecode.

    Returns:
        A rule implementation function for rb_library-like rules.
    """

    def _rb_library_impl(ctx):
        # TODO: avoid expanding the depset to a list, it may be expensive in a large graph
        transitive_data = get_transitive_data(ctx.files.data, ctx.attr.deps).to_list()
        transitive_deps = get_transitive_deps(ctx.attr.deps).to_list()
        transitive_srcs = get_transitive_srcs(ctx.files.srcs, ctx.attr.deps).to_list()

        bytecode_info = compile_to_bytecode(ctx)

        runfiles = ctx.runfiles(
            transitive_srcs + transitive_data + bytecode_info.bytecode_files,
        )
        runfiles = get_transitive_runfiles(
            runfiles,
            ctx.attr.srcs,
            ctx.attr.deps,
            ctx.attr.data,
        )

        providers = [
            DefaultInfo(
                files = depset(
                    transitive_srcs + transitive_data +
                    bytecode_info.bytecode_files,
                ),
                runfiles = runfiles,
            ),
            RubyFilesInfo(
                binary = None,
                transitive_data = depset(transitive_data),
                transitive_deps = depset(transitive_deps),
                transitive_srcs = depset(transitive_srcs),
                bundle_env = get_bundle_env(ctx.attr.bundle_env, ctx.attr.deps),
            ),
        ]

        # Add RubyBytecodeInfo if bytecode compilation is enabled
        if bytecode_info.provider:
            providers.append(bytecode_info.provider)

        for dep in transitive_deps:
            if BundlerInfo in dep:
                providers.append(dep[BundlerInfo])
                break

        return providers

    return _rb_library_impl

# We define some rb_library-like targets in rules_ruby. However, to avoid having
# to configure a ruby toolchain for rules_ruby's workspace, we define two
# versions of the library rules. rb_library is the one that should be used by
# clients. It requires a ruby toolchain. rb_library_wo_toolchains is for
# internal use only. It does not require a ruby toolchain.
rb_library_wo_toolchains = rule(
    implementation = _rb_library_impl_factory(
        compile_to_bytecode = _compile_to_bytecode_noop,
    ),
    attrs = ATTRS,
    doc = "For internal use only.",
)

rb_library = rule(
    implementation = _rb_library_impl_factory(
        compile_to_bytecode = _compile_to_bytecode,
    ),
    attrs = ATTRS,
    toolchains = ["@rules_ruby//ruby:toolchain_type"],
    doc = """
Defines a Ruby library.

Suppose you have the following Ruby gem:

```output
|-- BUILD
|-- Gemfile
|-- WORKSPACE
|-- gem.gemspec
`-- lib
    |-- BUILD
    |-- gem
    |   |-- BUILD
    |   |-- add.rb
    |   |-- subtract.rb
    |   `-- version.rb
    `-- gem.rb
```

You can define packages for the gem source files:

`BUILD`:
```bazel
load("@rules_ruby//ruby:defs.bzl", "rb_library")

package(default_visibility = ["//:__subpackages__"])

rb_library(
    name = "gem",
    deps = ["//lib:gem"],
)
```

`lib/BUILD`:
```bazel
load("@rules_ruby//ruby:defs.bzl", "rb_library")

package(default_visibility = ["//:__subpackages__"])

rb_library(
    name = "gem",
    srcs = ["gem.rb"],
    deps = [
        "//lib/gem:add",
        "//lib/gem:subtract",
        "//lib/gem:version",
    ],
)
```

`lib/gem/BUILD`:
```bazel
load("@rules_ruby//ruby:defs.bzl", "rb_library")

package(default_visibility = ["//:__subpackages__"])

rb_library(
    name = "add",
    srcs = ["add.rb"],
)

rb_library(
    name = "subtract",
    srcs = ["subtract.rb"],
)

rb_library(
    name = "version",
    srcs = ["version.rb"],
)
```

Once the packages are defined, you can use them in other targets
such as `rb_gem_build()` to build a Ruby gem. See examples of
using other rules.
    """,
)
