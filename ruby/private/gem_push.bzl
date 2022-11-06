load("//ruby/private:binary.bzl", "generate_rb_binary_script")
load("//ruby/private:providers.bzl", "get_transitive_srcs")

def _rb_gem_push_impl(ctx):
    print(ctx.toolchains["@rules_ruby//:toolchain_type"].gem)
    script = generate_rb_binary_script(
        ctx,
        ctx.toolchains["@rules_ruby//:toolchain_type"].gem,
        ["push", ctx.file.src.short_path]
    )

    runfiles = ctx.runfiles([ctx.file.src, ctx.toolchains["@rules_ruby//:toolchain_type"].gem])
    return [DefaultInfo(executable = script, runfiles = runfiles)]

rb_gem_push = rule(
    _rb_gem_push_impl,
    executable = True,
    attrs = {
        "src": attr.label(
            allow_single_file = True,
            mandatory = True,
        ),
        "_windows_constraint": attr.label(
            default = "@platforms//os:windows",
        ),
    },
    toolchains = ["@rules_ruby//:toolchain_type"],
)
