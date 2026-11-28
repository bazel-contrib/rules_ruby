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

_ALIAS_TPL = """alias(
    name = "{suffix}",
    actual = "{target}",
    visibility = ["//visibility:public"],
)
"""

def proxy_build_content(toolchains, toolchain_type):
    """Returns the BUILD file of a toolchain proxy repository.

    Args:
        toolchains: list of `repo|platform` entries.
        toolchain_type: label string of the Ruby toolchain type.

    Returns:
        One `toolchain()` and one `alias()` to the toolchain target per entry.
    """
    blocks = []
    for entry in toolchains:
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
            toolchain_type = toolchain_type,
            exec_compatible_with = exec_cw,
        ))
        blocks.append(_ALIAS_TPL.format(
            suffix = suffix,
            target = "@{}//:toolchain".format(repo),
        ))
    return "\n".join(blocks)

def _rb_toolchain_repository_proxy_impl(repository_ctx):
    repository_ctx.file("BUILD", proxy_build_content(
        repository_ctx.attr.toolchains,
        repository_ctx.attr.toolchain_type,
    ))

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

Each platform also gets an `alias()` named after it (for example
`:x86_64_linux`, or `:default` in single-platform mode) that points at the
toolchain target. Use it to declare your own `toolchain()` targets, for example
with `target_settings`, instead of registering `//:all`.
    """,
)
