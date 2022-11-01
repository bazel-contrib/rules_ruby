load("//ruby/private:providers.bzl", "get_transitive_srcs", "RubyFiles")

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
