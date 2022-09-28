# provider {{{1
RubyFiles = provider(fields = ["transitive_srcs"])
RubyInfo = provider(
    doc = "Ruby interpreter.",
    fields = ["interpreter"],
)

# https://bazel.build/rules/depsets
def get_transitive_srcs(srcs, deps):
  """Obtain the source files for a target and its transitive dependencies.

  Args:
    srcs: a list of source files
    deps: a list of targets that are direct dependencies
  Returns:
    a collection of the transitive sources
  """
  return depset(
        srcs,
        transitive = [dep[RubyFiles].transitive_srcs for dep in deps])


# }}} rb_library {{{1

def _rb_library_impl(ctx):
    transitive_srcs = get_transitive_srcs(ctx.files.srcs, ctx.attr.deps)
    return [RubyFiles(transitive_srcs = transitive_srcs)]

rb_library = rule(
    implementation = _rb_library_impl,
    attrs = {
        "srcs": attr.label_list(allow_files = True),
        "deps": attr.label_list(),
    }
)

# }}} rb_binary {{{1

_RUN_SCRIPT = """
{bin} {args}
"""

def _rb_binary_impl(ctx):
    if ctx.attr.bin:
        binary = ctx.executable.bin
    else:
        toolchain = ctx.toolchains["@rules_ruby//:toolchain_type"]
        binary = toolchain.ruby

    transitive_srcs = get_transitive_srcs(ctx.files.srcs, ctx.attr.deps)
    runfiles = ctx.runfiles(transitive_srcs.to_list() + [binary])

    script = ctx.actions.declare_file("{}.rb".format(ctx.label.name))
    ctx.actions.write(
        output = script,
        content = _RUN_SCRIPT.format(
            bin = binary.path,
            args = " ".join(ctx.attr.args),
        )
    )

    return [DefaultInfo(executable = script, runfiles = runfiles)]

rb_binary = rule(
    implementation = _rb_binary_impl,
    executable = True,
    attrs = {
        "srcs": attr.label_list(allow_files = True),
        "deps": attr.label_list(),
        "bin": attr.label(
            executable = True,
            allow_single_file = True,
            cfg = "exec",
        ),
    },
    toolchains = ["@rules_ruby//:toolchain_type"],
)

# }}} rb_test {{{1

rb_test = rule(
    implementation = _rb_binary_impl,
    test = True,
    attrs = {
        "srcs": attr.label_list(allow_files = True),
        "deps": attr.label_list(),
        "bin": attr.label(
            executable = True,
            allow_single_file = True,
            cfg = "exec",
        ),
    },
)

# }}} rb_gem {{{1

def _rb_gem_impl(ctx):
    gem_builder = ctx.actions.declare_file("{}_gem_builder.rb".format(ctx.label.name))
    toolchain = ctx.toolchains["@rules_ruby//:toolchain_type"]

    ctx.actions.expand_template(
        template = ctx.file._gem_builder_tpl,
        output = gem_builder,
        substitutions = {
            "{bazel_out_dir}": ctx.outputs.gem.dirname,
            "{gem_filename}": ctx.outputs.gem.basename,
            "{gemspec}": ctx.file.gemspec.path,
        },
    )

    args = ctx.actions.args()
    args.add(gem_builder)
    inputs = get_transitive_srcs(ctx.files.srcs + [gem_builder], ctx.attr.deps)
    ctx.actions.run(
        inputs = inputs,
        executable = toolchain.ruby,
        arguments = [args],
        outputs = [ctx.outputs.gem],
    )

rb_gem = rule(
    _rb_gem_impl,
    attrs = {
        "gemspec": attr.label(
            allow_single_file = True,
            mandatory = True,
        ),
        "srcs": attr.label_list(allow_files = True),
        "deps": attr.label_list(),
        "_gem_builder_tpl": attr.label(
            allow_single_file = True,
            default = "@rules_ruby//:gem_builder.rb.tpl",
        ),
    },
    outputs = {
        "gem": "%{name}.gem",
    },
    toolchains = ["@rules_ruby//:toolchain_type"],
)

# }}} rb_bundle {{{1

def _rb_bundle_impl(repository_ctx):
    binstubs_path = repository_ctx.path('bin')
    workspace_root = repository_ctx.path(repository_ctx.attr.gemfile).dirname

    repository_ctx.template(
        "BUILD",
        repository_ctx.attr._build_tpl,
        executable = False
    )

    repository_ctx.execute(
        [
            repository_ctx.path(repository_ctx.attr._bundle),
            "install",
        ],
        quiet = False,
        environment = {
            "BUNDLE_BIN": repr(binstubs_path),
            "BUNDLE_SHEBANG": repr(repository_ctx.path(repository_ctx.attr._ruby)),
        },
        working_directory = repr(workspace_root)
    )

rb_bundle = repository_rule(
    implementation = _rb_bundle_impl,
    local = True,
    attrs = {
        "srcs": attr.label_list(allow_files = True),
        "gemfile": attr.label(allow_single_file = True),
        "_ruby": attr.label(
            default = "@rules_ruby//:dist/bin/ruby",
            providers = [RubyInfo],
            executable = True,
            cfg = "exec",
            allow_files = True,
        ),
        "_bundle": attr.label(
            default = "@rules_ruby//:dist/bin/bundle",
            providers = [RubyInfo],
            executable = True,
            cfg = "exec",
            allow_files = True,
        ),
        "_build_tpl": attr.label(
            allow_single_file = True,
            default = "@rules_ruby//:bundle.BUILD.tpl",
        ),
    },
)

# }}} rb_toolchain {{{1

def rb_setup(toolchain = "@%s//:toolchain" % "rules_ruby"):
    native.register_toolchains(toolchain)

def rb_toolchain(name, ruby, bundle):
    toolchain_name = "%s_toolchain" % name

    _rb_toolchain(
        name = toolchain_name,
        ruby = ruby,
        bundle = bundle,
    )

    native.toolchain(
        name = name,
        toolchain = ":%s" % toolchain_name,
        toolchain_type = "@rules_ruby//:toolchain_type",
    )

def _rb_toolchain_impl(ctx):
    return platform_common.ToolchainInfo(
        ruby = ctx.executable.ruby,
        ruby_runfiles = ctx.runfiles(ctx.files.ruby).merge(
            ctx.attr.ruby[DefaultInfo].default_runfiles,
        ),
        bundle = ctx.executable.bundle,
        bundle_runfiles = ctx.runfiles(ctx.files.bundle).merge(
            ctx.attr.bundle[DefaultInfo].default_runfiles,
        ),
    )

_rb_toolchain = rule(
    implementation = _rb_toolchain_impl,
    attrs = {
        "ruby": attr.label(
            doc = "`ruby` binary to execute",
            allow_files = True,
            executable = True,
            cfg = "exec",
        ),
        "bundle": attr.label(
            doc = "`bundle` to execute",
            allow_files = True,
            executable = True,
            cfg = "exec",
        ),
    },
)

# }}}
# vim: foldmethod=marker
