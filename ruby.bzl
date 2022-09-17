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
{env} {bundle} exec {bin} {args}
"""

def _rb_binary_impl(ctx):
    transitive_srcs = get_transitive_srcs(ctx.files.srcs, ctx.attr.deps)
    runfiles = ctx.runfiles(transitive_srcs.to_list() + [ctx.executable._ruby, ctx.executable._bundle])

    script = ctx.actions.declare_file("{}.rb".format(ctx.label.name))
    ctx.actions.write(
        output = script,
        content = _RUN_SCRIPT.format(
            bundle = ctx.executable._bundle.path,
            bin = ctx.attr.bin,
            args = " ".join(ctx.attr.args),
            env = " ".join([
                "BUNDLE_DISABLE_SHARED_GEMS=true",
                "BUNDLE_PATH=external/bundle/vendor/bundle"
            ])
        )
    )

    return [DefaultInfo(executable = script, runfiles = runfiles)]

rb_binary = rule(
    implementation = _rb_binary_impl,
    executable = True,
    attrs = {
        "srcs": attr.label_list(allow_files = True),
        "deps": attr.label_list(),
        "bin": attr.string(),
        "_ruby": attr.label(
            default = "//ruby-build/dist/2.7/bin:ruby",
            providers = [RubyInfo],
            executable = True,
            cfg = "exec",
            allow_files = True,
        ),
        "_bundle": attr.label(
            default = "//ruby-build/dist/2.7/bin:bundle",
            providers = [RubyInfo],
            executable = True,
            cfg = "exec",
            allow_files = True,
        ),
    },
)

# }}} rb_bundle {{{1

def _rb_bundle_impl(repository_ctx):
    bundle_path = repository_ctx.path('vendor/bundle')
    workspace_root = repository_ctx.path(repository_ctx.attr.gemfile).dirname

    repository_ctx.template(
        "BUILD",
        repository_ctx.attr._build_tpl,
        substitutions = {
            "{bundle_path}": "vendor/bundle"
        },
        executable = False
    )

    repository_ctx.execute(
        [
            repository_ctx.path(repository_ctx.attr._bundle),
            "install",
        ],
        quiet = False,
        environment = {
            "BUNDLE_DISABLE_SHARED_GEMS": "true",
            "BUNDLE_JOBS": "4",
            "BUNDLE_PATH": repr(bundle_path),
            "BUNDLE_RETRY": "3",
        },
        working_directory = repr(workspace_root)
    )

rb_bundle = repository_rule(
    implementation = _rb_bundle_impl,
    local = True,
    attrs = {
        "srcs": attr.label_list(allow_files = True),
        "gemfile": attr.label(allow_single_file = True),
        "_bundle": attr.label(
            default = "//dist/2.7/bin:bundle",
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

# }}}
# vim: foldmethod=marker
