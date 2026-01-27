"Implementation details for rb_gem"

load("//ruby/private:providers.bzl", "GemInfo")

def _rb_gem_impl(ctx):
    gem = ctx.file.gem
    name, _, version = ctx.attr.name.rpartition("-")

    return [
        DefaultInfo(files = depset([gem])),
        GemInfo(
            name = name,
            version = version,
        ),
    ]

rb_gem = rule(
    _rb_gem_impl,
    attrs = {
        "gem": attr.label(
            allow_single_file = [".gem"],
            mandatory = True,
            doc = "Gem file.",
        ),
    },
    doc = """
Exposes a Ruby gem file.

You normally don't need to call this rule directly as it's an internal one
used by `rb_bundle_fetch()`.
    """,
)

def _rb_git_gem_impl(ctx):
    # type: (ctx) -> Unknown
    name, _, version = ctx.attr.name.rpartition("-")

    return [
        DefaultInfo(files = depset(ctx.files.srcs)),
        GemInfo(
            name = name,
            version = version,
        ),
    ]

rb_git_gem = rule(
    implementation = _rb_git_gem_impl,
    attrs = {
        "srcs": attr.label_list(
            allow_files = True,
            mandatory = True,
            doc = "Repository files.",
        ),
    },
)
