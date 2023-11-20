"Implementation details for calling the bundler"

# https://github.com/rubygems/rubygems/blob/f8c76eae24bbeabb9c9cb5387dbd89df45566eb9/bundler/lib/bundler/installer.rb#L147
_BINSTUB_CMD = """@ruby -x "%~f0" %*
@exit /b %ERRORLEVEL%
{}
"""

def _rb_bundle_impl(repository_ctx):
    binstubs_path = repository_ctx.path("bin")
    bundle_path = repository_ctx.path(".")
    gemfile_path = repository_ctx.path(repository_ctx.attr.gemfile)
    toolchain_path = repository_ctx.path(repository_ctx.attr.toolchain).dirname

    if repository_ctx.os.name.startswith("windows"):
        bundle = repository_ctx.path("%s/dist/bin/bundle.cmd" % toolchain_path)
        path_separator = ";"
        if repository_ctx.path("%s/dist/bin/jruby.exe" % toolchain_path).exists:
            ruby = repository_ctx.path("%s/dist/bin/jruby.exe" % toolchain_path)
        else:
            ruby = repository_ctx.path("%s/dist/bin/ruby.exe" % toolchain_path)
    else:
        bundle = repository_ctx.path("%s/dist/bin/bundle" % toolchain_path)
        path_separator = ":"
        if repository_ctx.path("%s/dist/bin/jruby" % toolchain_path).exists:
            ruby = repository_ctx.path("%s/dist/bin/jruby" % toolchain_path)
        else:
            ruby = repository_ctx.path("%s/dist/bin/ruby" % toolchain_path)

    repository_ctx.template(
        "BUILD",
        repository_ctx.attr._build_tpl,
        executable = False,
    )

    env = {
        "BUNDLE_BIN": repr(binstubs_path),
        "BUNDLE_GEMFILE": repr(gemfile_path),
        "BUNDLE_IGNORE_CONFIG": "1",
        "BUNDLE_PATH": repr(bundle_path),
        "BUNDLE_SHEBANG": repr(ruby),
        "PATH": path_separator.join([repr(ruby.dirname), repository_ctx.os.environ["PATH"]]),
    }
    env.update(repository_ctx.attr.env)

    bundle_env = {k: v for k, v in env.items() if k.startswith("BUNDLE_")}
    repository_ctx.file(
        "defs.bzl",
        "BUNDLE_ENV = %s" % bundle_env,
    )

    repository_ctx.report_progress("Running bundle install")
    result = repository_ctx.execute(
        [bundle, "install"],
        environment = env,
        working_directory = repr(gemfile_path.dirname),
        quiet = not repository_ctx.os.environ.get("RUBY_RULES_DEBUG", default = False),
    )

    if result.return_code != 0:
        fail("%s\n%s" % (result.stdout, result.stderr))

    # Check if there are missing Windows binstubs and generate them manually.
    # This is necessary on Ruby 2.7 with Bundler 2.1 and earlier.
    if not binstubs_path.get_child("bundle.cmd").exists:
        for binstub in binstubs_path.readdir():
            repository_ctx.file(
                "%s.cmd" % binstub,
                _BINSTUB_CMD.format(repository_ctx.read(binstub)),
            )

rb_bundle = repository_rule(
    implementation = _rb_bundle_impl,
    attrs = {
        "srcs": attr.label_list(
            allow_files = True,
            doc = """
List of Ruby source files used to build the library.
            """,
        ),
        "toolchain": attr.label(
            mandatory = True,
        ),
        "gemfile": attr.label(
            allow_single_file = ["Gemfile"],
            doc = """
Gemfile to install dependencies from.
            """,
        ),
        "env": attr.string_dict(
            doc = "Environment variables to use during installation.",
        ),
        "_build_tpl": attr.label(
            allow_single_file = True,
            default = "@rules_ruby//:ruby/private/bundle/BUILD.tpl",
        ),
    },
    doc = """
Installs Bundler dependencies and registers an external repository
that can be used by other targets.

`WORKSPACE`:
```bazel
load("@rules_ruby//ruby:deps.bzl", "rb_bundle")

rb_bundle(
    name = "bundle",
    gemfile = "//:Gemfile",
    srcs = [
        "//:gem.gemspec",
        "//:lib/gem/version.rb",
    ]
)
```

All the installed gems can be accessed using `@bundle` target and additionally
gems binary files can also be used:

`BUILD`:
```bazel
load("@rules_ruby//ruby:defs.bzl", "rb_binary")

package(default_visibility = ["//:__subpackages__"])

rb_binary(
    name = "rubocop",
    main = "@bundle//:bin/rubocop",
    deps = ["@bundle"],
)
```
    """,
)
