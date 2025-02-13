"Implementation details for rb_binary"

load("//ruby/private:library.bzl", LIBRARY_ATTRS = "ATTRS")
load(
    "//ruby/private:providers.bzl",
    "BundlerInfo",
    "RubyFilesInfo",
    "get_bundle_env",
    "get_transitive_data",
    "get_transitive_deps",
    "get_transitive_runfiles",
    "get_transitive_srcs",
)
load(
    "//ruby/private:utils.bzl",
    "BASH_RLOCATION_FUNCTION",
    "BATCH_RLOCATION_FUNCTION",
    _convert_env_to_script = "convert_env_to_script",
    _is_windows = "is_windows",
    _normalize_path = "normalize_path",
    _to_rlocation_path = "to_rlocation_path",
)

ATTRS = {
    "main": attr.label(
        executable = True,
        allow_files = True,
        cfg = "exec",
        doc = """
Ruby script to run. It may also be a binary stub generated by Bundler.
If omitted, it defaults to the Ruby interpreter.

Use a built-in `args` attribute to pass extra arguments to the script.
        """,
    ),
    "env": attr.string_dict(
        doc = """
Environment variables to use during execution.

Supports `$(location)` expansion for targets from `srcs`, `data` and `deps`.
""",
    ),
    "env_inherit": attr.string_list(
        doc = "List of environment variable names to be inherited by the test runner.",
    ),
    "ruby": attr.label(
        doc = "Override Ruby toolchain to use when running the script.",
        providers = [platform_common.ToolchainInfo],
    ),
    "_binary_cmd_tpl": attr.label(
        allow_single_file = True,
        default = "@rules_ruby//ruby/private/binary:binary.cmd.tpl",
    ),
    "_binary_sh_tpl": attr.label(
        allow_single_file = True,
        default = "@rules_ruby//ruby/private/binary:binary.sh.tpl",
    ),
    "_runfiles_library": attr.label(
        allow_single_file = True,
        default = "@bazel_tools//tools/bash/runfiles",
    ),
    "_windows_constraint": attr.label(
        default = "@platforms//os:windows",
    ),
}

# buildifier: disable=function-docstring
def generate_rb_binary_script(ctx, binary, bundler = False, args = [], env = {}, java_bin = ""):
    toolchain = ctx.toolchains["@rules_ruby//ruby:toolchain_type"]
    if ctx.attr.ruby != None:
        toolchain = ctx.attr.ruby[platform_common.ToolchainInfo]

    binary_path = ""
    locate_binary_in_runfiles = ""
    if binary and binary != toolchain.ruby:
        binary_path = binary.short_path

        # Runfiles library for Windows does not support generated directories,
        # so for now we skip locating the binary in runfiles. This only prevents
        # running binary scripts directly and should not affect normal `bazel run`.
        # See BATCH_RLOCATION_FUNCTION comments for more details.
        if binary_path.startswith("../") and not _is_windows(ctx):
            binary_path = _to_rlocation_path(binary)
            locate_binary_in_runfiles = "true"
        else:
            binary_path = _normalize_path(ctx, binary_path)

    environment = {}
    environment.update(env)
    for k, v in environment.items():
        environment[k] = ctx.expand_location(v, ctx.attr.srcs + ctx.attr.data + ctx.attr.deps)

    if _is_windows(ctx):
        rlocation_function = BATCH_RLOCATION_FUNCTION
        script = ctx.actions.declare_file("{}.cmd".format(ctx.label.name))
        template = ctx.file._binary_cmd_tpl
    else:
        rlocation_function = BASH_RLOCATION_FUNCTION
        script = ctx.actions.declare_file("{}.sh".format(ctx.label.name))
        template = ctx.file._binary_sh_tpl

    if bundler:
        bundler_command = "bundle exec"
    else:
        bundler_command = ""

    args = " ".join(args)
    args = ctx.expand_location(args, ctx.attr.srcs + ctx.attr.data + ctx.attr.deps)

    ctx.actions.expand_template(
        template = template,
        output = script,
        is_executable = True,
        substitutions = {
            "{args}": args,
            "{binary}": binary_path,
            "{env}": _convert_env_to_script(ctx, environment),
            "{bundler_command}": bundler_command,
            "{ruby}": _to_rlocation_path(toolchain.ruby),
            "{ruby_binary_name}": toolchain.ruby.basename,
            "{java_bin}": java_bin,
            "{rlocation_function}": rlocation_function,
            "{locate_binary_in_runfiles}": locate_binary_in_runfiles,
        },
    )

    return script

# buildifier: disable=function-docstring
def rb_binary_impl(ctx):
    bundler = False
    bundler_srcs = []
    env = {}
    java_bin = ""

    # TODO: avoid expanding the depset to a list, it may be expensive in a large graph
    transitive_data = get_transitive_data(ctx.files.data, ctx.attr.deps)
    transitive_deps = get_transitive_deps(ctx.attr.deps)
    transitive_srcs = get_transitive_srcs(ctx.files.srcs, ctx.attr.deps)

    ruby_toolchain = ctx.toolchains["@rules_ruby//ruby:toolchain_type"]
    if ctx.attr.ruby != None:
        ruby_toolchain = ctx.attr.ruby[platform_common.ToolchainInfo]
    tools = [ctx.file._runfiles_library]
    tools.extend(ruby_toolchain.files)

    if ruby_toolchain.version.startswith("jruby"):
        java_toolchain = ctx.toolchains["@bazel_tools//tools/jdk:runtime_toolchain_type"]
        tools.extend(java_toolchain.java_runtime.files.to_list())
        java_bin = java_toolchain.java_runtime.java_executable_runfiles_path[3:]

    for dep in transitive_deps.to_list():
        # TODO: Remove workspace name check together with `rb_bundle()`
        if dep.label.workspace_name.endswith("bundle"):
            bundler = True

        if BundlerInfo in dep:
            info = dep[BundlerInfo]
            bundler_srcs.extend([info.gemfile, info.bin, info.path])
            bundler = True

            # See https://bundler.io/v2.5/man/bundle-config.1.html for confiugration keys.
            env.update({
                "BUNDLE_GEMFILE": _to_rlocation_path(info.gemfile),
                "BUNDLE_PATH": _to_rlocation_path(info.path),
            })
    if len(bundler_srcs) > 0:
        transitive_srcs = depset(bundler_srcs, transitive = [transitive_srcs])

    bundle_env = get_bundle_env(ctx.attr.env, ctx.attr.deps)
    env.update(bundle_env)
    env.update(ruby_toolchain.env)
    env.update(ctx.attr.env)

    runfiles = ctx.runfiles(tools, transitive_files = depset(transitive = [transitive_srcs, transitive_data]))
    runfiles = get_transitive_runfiles(runfiles, ctx.attr.srcs, ctx.attr.deps, ctx.attr.data)

    # Propagate executable from source rb_binary() targets.
    executable = ctx.executable.main
    if ctx.attr.main and RubyFilesInfo in ctx.attr.main and ctx.attr.main[RubyFilesInfo].binary:
        executable = ctx.attr.main[RubyFilesInfo].binary

    script = generate_rb_binary_script(
        ctx,
        executable,
        bundler = bundler,
        env = env,
        java_bin = java_bin,
    )

    return [
        DefaultInfo(
            executable = script,
            files = depset(transitive = [transitive_srcs, depset(tools, transitive = [transitive_data])]),
            runfiles = runfiles,
        ),
        RubyFilesInfo(
            binary = executable,
            transitive_data = depset(tools, transitive = [transitive_data]),
            transitive_deps = transitive_deps,
            transitive_srcs = transitive_srcs,
            bundle_env = bundle_env,
        ),
        RunEnvironmentInfo(
            environment = env,
            inherited_environment = ctx.attr.env_inherit,
        ),
    ]

rb_binary = rule(
    implementation = rb_binary_impl,
    executable = True,
    attrs = dict(
        ATTRS,
        srcs = LIBRARY_ATTRS["srcs"],
        data = LIBRARY_ATTRS["data"],
        deps = LIBRARY_ATTRS["deps"],
    ),
    toolchains = [
        "@rules_ruby//ruby:toolchain_type",
        "@bazel_tools//tools/jdk:runtime_toolchain_type",
    ],
    doc = """
Runs a Ruby binary.

Suppose you have the following Ruby gem, where `rb_library()` is used
in `BUILD` files to define the packages for the gem.

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

One of the files can be run as a Ruby script:

`lib/gem/version.rb`:
```ruby
module GEM
  VERSION = '0.1.0'
end

puts "Version is: #{GEM::VERSION}" if __FILE__ == $PROGRAM_NAME
```

You can run this script by defining a target:

`lib/gem/BUILD`:
```bazel
load("@rules_ruby//ruby:defs.bzl", "rb_binary", "rb_library")

rb_library(
    name = "version",
    srcs = ["version.rb"],
)

rb_binary(
    name = "print-version",
    args = ["lib/gem/version.rb"],
    deps = [":version"],
)
```

```output
$ bazel run lib/gem:print-version
...
Version is: 0.1.0
```

You can also run general purpose Ruby scripts that rely on a Ruby interpreter in PATH:

`lib/gem/add.rb`:
```ruby
#!/usr/bin/env ruby

a, b = *ARGV
puts Integer(a) + Integer(b)
```

`lib/gem/BUILD`:
```bazel
load("@rules_ruby//ruby:defs.bzl", "rb_binary", "rb_library")

rb_library(
    name = "add",
    srcs = ["add.rb"],
)

rb_binary(
    name = "add-numbers",
    main = "add.rb",
    deps = [":add"],
)
```

```output
$ bazel run lib/gem:add-numbers 1 2
...
3
```

You can also run a Ruby binary script available in Gemfile dependencies,
by passing `bin` argument with a path to a Bundler binary stub:

`BUILD`:
```bazel
load("@rules_ruby//ruby:defs.bzl", "rb_binary")

package(default_visibility = ["//:__subpackages__"])

rb_binary(
    name = "rake",
    main = "@bundle//bin:rake",
    deps = [
        "//lib:gem",
        "@bundle",
    ],
)
```

```output
$ bazel run :rake -- --version
...
rake, version 13.1.0
```
    """,
)
