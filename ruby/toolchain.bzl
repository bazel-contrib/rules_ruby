"Define a Bazel toolchain for a Ruby interpreter"

def _rb_toolchain_impl(ctx):
    return platform_common.ToolchainInfo(
        ruby = ctx.executable.ruby,
        bundle = ctx.executable.bundle,
        gem = ctx.executable.gem,
        version = ctx.attr.version,
        env = ctx.attr.env,
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
        "files": attr.label_list(
            allow_files = True,
            doc = "All files necessary for toolchain",
        ),
    },
)
