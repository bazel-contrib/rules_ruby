"Repository rule for proxying registering Ruby interpreters"

load("//ruby/private/toolchain:platforms.bzl", "PLATFORM_CONSTRAINTS")

_TOOLCHAIN_TPL = """toolchain(
    name = "toolchain_{suffix}",
    toolchain = "{target}",
    toolchain_type = "{toolchain_type}",
    exec_compatible_with = {exec_compatible_with},
    visibility = ["//visibility:public"],
)
"""

def _rb_toolchain_repository_proxy_impl(repository_ctx):
    blocks = []
    for entry in repository_ctx.attr.toolchains:
        repo, _, plat = entry.partition("|")
        if plat:
            if plat not in PLATFORM_CONSTRAINTS:
                fail("Unknown platform key for toolchain proxy: {}".format(plat))
            suffix = plat
            exec_cw = repr(PLATFORM_CONSTRAINTS[plat])
        else:
            suffix = "default"
            exec_cw = "[]"
        blocks.append(_TOOLCHAIN_TPL.format(
            suffix = suffix,
            target = "@{}//:toolchain".format(repo),
            toolchain_type = repository_ctx.attr.toolchain_type,
            exec_compatible_with = exec_cw,
        ))
    repository_ctx.file("BUILD", "\n".join(blocks))

rb_toolchain_repository_proxy = repository_rule(
    implementation = _rb_toolchain_repository_proxy_impl,
    attrs = {
        "toolchains": attr.string_list(
            mandatory = True,
            doc = "List of `repo|platform` entries. An empty platform suffix " +
                  "registers an unconstrained toolchain (legacy single-platform mode).",
        ),
        "toolchain_type": attr.string(mandatory = True),
    },
    doc = """
A proxy repository containing one or more `toolchain()` declarations that
forward to per-platform Ruby repositories. Per-platform constraints come from
`PLATFORM_CONSTRAINTS`. This indirection lets Bazel resolve a Ruby toolchain
lazily (only the platform that matches gets materialized).
    """,
)
