"Implementation details for rb_gem_push"

load("//ruby/private:binary.bzl", "generate_rb_binary_script", BINARY_ATTRS = "ATTRS")
load("//ruby/private:library.bzl", LIBRARY_ATTRS = "ATTRS")

def _rb_gem_push_impl(ctx):
    env = {}
    java_toolchain = ctx.toolchains["@bazel_tools//tools/jdk:runtime_toolchain_type"]
    ruby_toolchain = ctx.toolchains["@rules_ruby//ruby:toolchain_type"]
    srcs = [ctx.file.gem]
    tools = [ruby_toolchain.gem, ctx.file._runfiles_library]

    if ruby_toolchain.version.startswith("jruby"):
        env["JAVA_HOME"] = java_toolchain.java_runtime.java_home
        tools.extend(java_toolchain.java_runtime.files.to_list())

    script = generate_rb_binary_script(
        ctx,
        binary = ruby_toolchain.gem,
        bundler = False,
        args = ["push", ctx.file.gem.short_path],
    )

    runfiles = ctx.runfiles(srcs + tools)
    env.update(ctx.attr.env)

    return [
        DefaultInfo(
            executable = script,
            runfiles = runfiles,
        ),
        RunEnvironmentInfo(
            environment = env,
            inherited_environment = ctx.attr.env_inherit,
        ),
    ]

rb_gem_push = rule(
    _rb_gem_push_impl,
    executable = True,
    attrs = dict(
        LIBRARY_ATTRS,
        gem = attr.label(
            allow_single_file = [".gem"],
            mandatory = True,
            doc = """
Gem file to push to RubyGems. You would usually use an output of `rb_gem_build()` target here.
            """,
        ),
        env = BINARY_ATTRS["env"],
        env_inherit = BINARY_ATTRS["env_inherit"],
        _binary_cmd_tpl = BINARY_ATTRS["_binary_cmd_tpl"],
        _binary_sh_tpl = BINARY_ATTRS["_binary_sh_tpl"],
        _windows_constraint = BINARY_ATTRS["_windows_constraint"],
        _runfiles_library = BINARY_ATTRS["_runfiles_library"],
    ),
    toolchains = [
        "@rules_ruby//ruby:toolchain_type",
        "@bazel_tools//tools/jdk:runtime_toolchain_type",
    ],
    doc = """
Pushes a built Ruby gem.

Suppose you have the following Ruby gem, where `rb_library()` is used
in `BUILD` files to define the packages for the gem and `rb_gem_build()` is used
to build a Ruby gem package from the sources.

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

You can now release the built `.gem` file to RubyGems by defining a target:

`BUILD`:
```bazel
load("@rules_ruby//ruby:defs.bzl", "rb_gem_build", "rb_gem_push")

package(default_visibility = ["//:__subpackages__"])

rb_gem_build(
    name = "gem-build",
    gemspec = "gem.gemspec",
    deps = ["//lib:gem"],
)

rb_gem_push(
    name = "gem-release",
    gem = ":gem-build",
)
```

```output
$ bazel run :gem-release
INFO: Analyzed target //:gem-release (3 packages loaded, 14 targets configured).
INFO: Found 1 target...
Target //:gem-release up-to-date:
  bazel-bin/gem-release.rb.sh
INFO: Elapsed time: 0.113s, Critical Path: 0.01s
INFO: 4 processes: 4 internal.
INFO: Build completed successfully, 4 total actions
INFO: Build completed successfully, 4 total actions
Pushing gem to https://rubygems.org...
Successfully registered gem: example (0.1.0)
```
    """,
)
