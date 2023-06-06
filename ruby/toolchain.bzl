def rb_toolchain(name, ruby, bundle, gem, bindir, version):
    toolchain_name = "%s_toolchain" % name

    _rb_toolchain(
        name = toolchain_name,
        ruby = ruby,
        bundle = bundle,
        gem = gem,
        bindir = bindir,
        version = version,
    )

    native.toolchain(
        name = name,
        toolchain = ":%s" % toolchain_name,
        toolchain_type = "@rules_ruby//ruby:toolchain_type",
    )

def _rb_toolchain_impl(ctx):
    return platform_common.ToolchainInfo(
        ruby = ctx.executable.ruby,
        bundle = ctx.executable.bundle,
        gem = ctx.executable.gem,
        bindir = ctx.attr.bindir,
        version = ctx.attr.version,
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
        "gem": attr.label(
            doc = "`gem` to execute",
            allow_files = True,
            executable = True,
            cfg = "exec",
        ),
        "bindir": attr.string(
            doc = "Path to Ruby bin/ directory",
        ),
        "version": attr.string(
            doc = "Ruby version",
        ),
    },
)
