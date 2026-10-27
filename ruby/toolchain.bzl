"Define a Bazel toolchain for a Ruby interpreter"

def _rb_toolchain_impl(ctx):
    return platform_common.ToolchainInfo(
        ruby = ctx.executable.ruby,
        bundle = ctx.executable.bundle,
        gem = ctx.executable.gem,
        version = ctx.attr.version,
        env = ctx.attr.env,
        bundle_build_env = ctx.attr.bundle_build_env,
        files = ctx.files.files,
    )

rb_toolchain = rule(
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
        "gem": attr.label(
            doc = "`gem` to execute",
            allow_files = True,
            executable = True,
            cfg = "exec",
        ),
        "version": attr.string(
            doc = "Ruby version",
        ),
        "env": attr.string_dict(
            doc = "Environment variables required by an interpreter",
        ),
        "bundle_build_env": attr.string_dict(
            doc = """
Bundler build options (`BUNDLE_BUILD__<GEM>`) used when compiling native extensions.
Values have the form `<flag>=<path>`, where `<path>` is relative to the directory
two levels above `ruby` (the toolchain repository root for downloaded Rubies).
`rb_bundle_install` and `rb_gem_install` make the path absolute when the action
runs, so no absolute path is stored in the toolchain.
""",
        ),
        "files": attr.label_list(
            allow_files = True,
            doc = "All files necessary for toolchain",
        ),
    },
)
