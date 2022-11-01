def _rb_bundle_impl(repository_ctx):
    binstubs_path = repository_ctx.path('bin')
    workspace_root = repository_ctx.path(repository_ctx.attr.gemfile).dirname

    if repository_ctx.os.name.startswith("windows"):
        bundle = repository_ctx.path(Label("@rules_ruby_dist//:dist/bin/bundle.cmd"))
        ruby = repository_ctx.path(Label("@rules_ruby_dist//:dist/bin/ruby.exe"))
    else:
        bundle = repository_ctx.path(Label("@rules_ruby_dist//:dist/bin/bundle"))
        ruby = repository_ctx.path(Label("@rules_ruby_dist//:dist/bin/ruby"))

    repository_ctx.template(
        "BUILD",
        repository_ctx.attr._build_tpl,
        executable = False
    )

    repository_ctx.report_progress("Running bundle install")
    result = repository_ctx.execute(
        [
            bundle,
            "install",
        ],
        environment = {
            "BUNDLE_BIN": repr(binstubs_path),
            "BUNDLE_SHEBANG": repr(ruby),
        },
        working_directory = repr(workspace_root),
    )

    if result.return_code != 0:
        fail("%s\n%s" % (result.stdout, result.stderr))

rb_bundle = repository_rule(
    implementation = _rb_bundle_impl,
    attrs = {
        "srcs": attr.label_list(allow_files = True),
        "gemfile": attr.label(allow_single_file = True),
        "_build_tpl": attr.label(
            allow_single_file = True,
            default = "@rules_ruby//:ruby/private/bundle/BUILD.tpl",
        ),
    },
)
