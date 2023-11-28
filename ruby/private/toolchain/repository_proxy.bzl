"Repository rule for proxying registering Ruby interpreters"

def _rb_toolchain_repository_proxy_impl(repository_ctx):
    repository_ctx.template(
        "BUILD",
        repository_ctx.attr._build_tpl,
        substitutions = {
            "{name}": repository_ctx.attr.name,
            "{toolchain}": repository_ctx.attr.toolchain,
            "{toolchain_type}": repository_ctx.attr.toolchain_type,
        },
        executable = False,
    )

rb_toolchain_repository_proxy = repository_rule(
    implementation = _rb_toolchain_repository_proxy_impl,
    attrs = {
        "toolchain": attr.string(mandatory = True),
        "toolchain_type": attr.string(mandatory = True),
        "_build_tpl": attr.label(
            allow_single_file = True,
            default = "@rules_ruby//:ruby/private/toolchain/repository_proxy/BUILD.tpl",
        ),
    },
    doc = """
A proxy repository that contains the toolchain declaration; this indirection
allows the Ruby toolchain to be downloaded lazily.
    """,
)
