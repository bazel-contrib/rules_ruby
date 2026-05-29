"Hub repository rule for multi-platform Ruby toolchains."

load("//ruby/private/toolchain:platforms.bzl", "PLATFORM_CONSTRAINTS")

# Canonical bin targets exposed by `download/BUILD.tpl` for an MRI Ruby install.
_MRI_BINS = [
    "bundle",
    "bundler",
    "erb",
    "gem",
    "irb",
    "racc",
    "rake",
    "rbs",
    "rdbg",
    "rdoc",
    "ri",
    "ruby",
]

# Canonical bin targets exposed by `download/BUILD.tpl` for a JRuby install.
_JRUBY_BINS = [
    "jruby",
    "jirb",
    "jgem",
    "jrake",
    "bundle",
    "bundler",
    "gem",
    "rake",
    "irb",
    "rdoc",
    "ri",
]

# Targets that always exist in a per-platform repo regardless of engine.
_STATIC_ALIASES = [
    "ruby",
    "ruby_file",
    "toolchain",
    "headers",
    "jars",
]

def _emit_config_settings(platforms):
    blocks = []
    for plat in platforms:
        cv = PLATFORM_CONSTRAINTS[plat]
        blocks.append(
            'config_setting(name = "is_{p}", constraint_values = {cv})'.format(
                p = plat,
                cv = repr(cv),
            ),
        )
    return "\n".join(blocks)

def _emit_alias(name, hub_name, platforms):
    branches = []
    for plat in platforms:
        branches.append(
            '        ":is_{p}": "@{hub}_{p}//:{name}"'.format(
                p = plat,
                hub = hub_name,
                name = name,
            ),
        )
    return (
        "alias(\n" +
        '    name = "{name}",\n'.format(name = name) +
        "    actual = select({\n" +
        ",\n".join(branches) + ",\n" +
        "    }),\n" +
        '    visibility = ["//visibility:public"],\n' +
        ")"
    )

def _rb_hub_repository_impl(repository_ctx):
    # `repository_ctx.attr.name` returns the canonical name under bzlmod, which is
    # not the apparent name the per-platform repos are siblings under. We use the
    # explicit `apparent_name` attr so the generated BUILD references repos by their
    # apparent names (visible to each other when created by the same extension).
    hub_name = repository_ctx.attr.apparent_name
    platforms = repository_ctx.attr.platforms
    engine = repository_ctx.attr.engine

    if engine == "jruby":
        bins = _JRUBY_BINS
    else:
        bins = _MRI_BINS

    # _STATIC_ALIASES contains "ruby", which is also in _MRI_BINS — deduplicate
    # while preserving order so the generated BUILD is deterministic.
    alias_names = []
    seen = {}
    for n in _STATIC_ALIASES + bins:
        if n in seen:
            continue
        seen[n] = True
        alias_names.append(n)

    parts = [
        'package(default_visibility = ["//visibility:public"])',
        _emit_config_settings(platforms),
    ]
    for n in alias_names:
        parts.append(_emit_alias(n, hub_name, platforms))

    repository_ctx.file("BUILD", "\n\n".join(parts) + "\n")

    repository_ctx.template(
        "engine/BUILD",
        repository_ctx.attr._engine_tpl,
        executable = False,
        substitutions = {
            "{ruby_engine}": engine,
        },
    )

rb_hub_repository = repository_rule(
    implementation = _rb_hub_repository_impl,
    attrs = {
        "apparent_name": attr.string(
            mandatory = True,
            doc = """
Apparent name of this hub (matches `name=` passed to `rb_register_toolchains`) used to construct sibling per-platform apparent labels in the generated BUILD.
            """,
        ),
        "platforms": attr.string_list(
            mandatory = True,
            doc = "Canonical platform keys whose per-platform repos this hub aliases.",
        ),
        "engine": attr.string(
            mandatory = True,
            values = ["ruby", "jruby", "truffleruby"],
            doc = "Ruby engine for `engine/BUILD` config_settings.",
        ),
        "_engine_tpl": attr.label(
            allow_single_file = True,
            default = "@rules_ruby//:ruby/private/download/BUILD.engine.tpl",
        ),
    },
    doc = """
A hub repository whose BUILD file contains `alias()` targets pointing to the
matching per-platform `@<hub>_<platform>` repository via `select()` on
@platforms constraints. This preserves backwards compatibility with direct
references like `@ruby//:bundle` while the actual Ruby interpreter lives in a
per-platform repo selected by Bazel's toolchain/platform resolution.
    """,
)
