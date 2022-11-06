load("//ruby/private:providers.bzl", "get_transitive_srcs")

_SH_SCRIPT = "{binary} {args} $@"

# We have to explicitly set PATH on Windows because bundler
# binstubs rely on calling Ruby available globally.
# https://github.com/rubygems/rubygems/issues/3381#issuecomment-645026943

_CMD_BINARY_SCRIPT = """
@set PATH={toolchain_bindir};%PATH%
@call {binary}.cmd {args} %*
"""

# Calling ruby.exe directly throws strange error so we rely on PATH instead.

_CMD_RUBY_SCRIPT = """
@set PATH={toolchain_bindir};%PATH%
@ruby {args} %*
"""

def generate_rb_binary_script(ctx, binary, args):
    windows_constraint = ctx.attr._windows_constraint[platform_common.ConstraintValueInfo]
    is_windows = ctx.target_platform_has_constraint(windows_constraint)
    toolchain = ctx.toolchains["@rules_ruby//:toolchain_type"]
    toolchain_bindir = toolchain.bindir

    if binary:
        binary_path = binary.path
    else:
        binary_path = toolchain.ruby.path

    if is_windows:
        binary_path = binary_path.replace("/", "\\")
        script = ctx.actions.declare_file("{}.rb.cmd".format(ctx.label.name))
        toolchain_bindir = toolchain_bindir.replace("/", "\\")
        if binary:
            template = _CMD_RUBY_SCRIPT
        else:
            template = _CMD_BINARY_SCRIPT
    else:
        script = ctx.actions.declare_file("{}.rb.sh".format(ctx.label.name))
        template = _SH_SCRIPT

    args = " ".join(args)
    args = ctx.expand_location(args)

    ctx.actions.write(
        output = script,
        is_executable = True,
        content = template.format(
            args = args,
            binary = binary_path,
            toolchain_bindir = toolchain_bindir,
        ),
    )

    return script

def rb_binary_impl(ctx):
    script = generate_rb_binary_script(ctx, ctx.executable.bin, ctx.attr.args)
    transitive_srcs = get_transitive_srcs(ctx.files.srcs, ctx.attr.deps).to_list()
    if not ctx.attr.bin:
        transitive_srcs += [ctx.toolchains["@rules_ruby//:toolchain_type"].ruby]
    runfiles = ctx.runfiles(transitive_srcs)

    return [DefaultInfo(executable = script, runfiles = runfiles)]

rb_binary = rule(
    implementation = rb_binary_impl,
    executable = True,
    attrs = {
        "srcs": attr.label_list(allow_files = True),
        "deps": attr.label_list(),
        "bin": attr.label(
            executable = True,
            allow_single_file = True,
            cfg = "exec",
        ),
        "_windows_constraint": attr.label(
            default = "@platforms//os:windows",
        ),
    },
    toolchains = ["@rules_ruby//:toolchain_type"],
)
