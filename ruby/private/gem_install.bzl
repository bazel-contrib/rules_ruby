"Implementation details for rb_gem_install"

load("//ruby/private:providers.bzl", "GemInfo")
load(
    "//ruby/private:utils.bzl",
    _convert_env_to_script = "convert_env_to_script",
    _is_windows = "is_windows",
    _normalize_path = "normalize_path",
)

def _rb_gem_install_impl(ctx):
    gem = ctx.file.gem
    install_dir = ctx.actions.declare_directory(gem.basename[:-4])
    toolchain = ctx.toolchains["@rules_ruby//ruby:toolchain_type"]

    env = {}
    env.update(toolchain.env)

    tools = []
    tools.extend(toolchain.files)

    if toolchain.version.startswith("jruby"):
        java_toolchain = ctx.toolchains["@bazel_tools//tools/jdk:runtime_toolchain_type"]
        tools.extend(java_toolchain.java_runtime.files.to_list())
        env.update({"JAVA_HOME": java_toolchain.java_runtime.java_home})

    if _is_windows(ctx):
        gem_install = ctx.actions.declare_file("gem_install_{}.cmd".format(ctx.label.name))
        template = ctx.file._gem_install_cmd_tpl
        env.update({"PATH": _normalize_path(ctx, toolchain.ruby.dirname) + ";%PATH%"})
    else:
        gem_install = ctx.actions.declare_file("gem_install_{}.sh".format(ctx.label.name))
        template = ctx.file._gem_install_sh_tpl
        env.update({"PATH": "%s:$PATH" % toolchain.ruby.dirname})

    ctx.actions.expand_template(
        template = template,
        output = gem_install,
        substitutions = {
            "{env}": _convert_env_to_script(ctx, env),
            "{gem_binary}": _normalize_path(ctx, toolchain.gem.path),
            "{gem}": gem.path,
            "{install_dir}": install_dir.path,
        },
    )

    name, _, version = ctx.attr.name.rpartition("-")
    ctx.actions.run(
        executable = gem_install,
        inputs = depset([gem, gem_install]),
        outputs = [install_dir],
        mnemonic = "GemInstall",
        progress_message = "Installing %{input} (%{label})",
        tools = tools,
        use_default_shell_env = True,
    )

    return [
        DefaultInfo(files = depset([gem, install_dir])),
        GemInfo(
            name = name,
            version = version,
        ),
    ]

rb_gem_install = rule(
    _rb_gem_install_impl,
    attrs = {
        "gem": attr.label(
            allow_single_file = [".gem"],
            mandatory = True,
            doc = "Gem file to install.",
        ),
        "_gem_install_cmd_tpl": attr.label(
            allow_single_file = True,
            default = "@rules_ruby//ruby/private/gem_install:gem_install.cmd.tpl",
        ),
        "_gem_install_sh_tpl": attr.label(
            allow_single_file = True,
            default = "@rules_ruby//ruby/private/gem_install:gem_install.sh.tpl",
        ),
        "_windows_constraint": attr.label(
            default = "@platforms//os:windows",
        ),
    },
    toolchains = [
        "@rules_ruby//ruby:toolchain_type",
        "@bazel_tools//tools/jdk:runtime_toolchain_type",
    ],
    doc = """
Installs a built Ruby gem.

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

You can now install the built `.gem` file by defining a target:

`BUILD`:
```bazel
load("@rules_ruby//ruby:defs.bzl", "rb_gem_build", "rb_gem_install")

package(default_visibility = ["//:__subpackages__"])

rb_gem_build(
    name = "gem-build",
    gemspec = "gem.gemspec",
    deps = ["//lib:gem"],
)

rb_gem_install(
    name = "gem-install",
    gem = ":gem-build",
)
```

```output
$ bazel build :gem-install
...
Successfully installed example-0.1.0
1 gem installed
...
```
    """,
)
