def rb_download(version):
    _rb_download(
        name = "rules_ruby_dist",
        version = version,
    )
    native.register_toolchains("@rules_ruby_dist//:toolchain")

def _rb_download_impl(repository_ctx):
    if repository_ctx.os.name.startswith("windows"):
        repository_ctx.report_progress("Downloading RubyInstaller")
        repository_ctx.download(
            url = "https://github.com/oneclick/rubyinstaller2/releases/download/RubyInstaller-%s-1/rubyinstaller-devkit-%s-1-x64.exe" % (repository_ctx.attr.version, repository_ctx.attr.version),
            output = "ruby-installer.exe",
        )

        repository_ctx.report_progress("Installing Ruby")
        result = repository_ctx.execute([
            "./ruby-installer.exe",
            "/components=ruby,msys2",
            "/dir=dist",
            "/tasks=nomodpath,noassocfiles",
            "/verysilent",
        ])
    else:
        repository_ctx.report_progress("Downloading ruby-build")
        repository_ctx.download_and_extract(
            url = "https://github.com/rbenv/ruby-build/archive/refs/tags/v%s.tar.gz" % repository_ctx.attr._ruby_build_version,
            output = "ruby-build",
            stripPrefix = "ruby-build-%s" % repository_ctx.attr._ruby_build_version,
        )

        repository_ctx.report_progress("Installing Ruby")
        result = repository_ctx.execute(["ruby-build/bin/ruby-build", repository_ctx.attr.version, "dist"])

    if result.return_code != 0:
        fail("%s\n%s" % (result.stdout, result.stderr))

    repository_ctx.template(
        "BUILD",
        repository_ctx.attr._build_tpl,
        executable = False,
        substitutions = {
            "{bindir}": repr(repository_ctx.path("dist/bin")),
        },
    )

_rb_download = repository_rule(
    implementation = _rb_download_impl,
    attrs = {
        "version": attr.string(
            mandatory = True,
        ),
        "_ruby_build_version": attr.string(
            default = "20221026",
        ),
        "_build_tpl": attr.label(
            allow_single_file = True,
            default = "@rules_ruby//:ruby/private/download/BUILD.tpl",
        ),
    },
)
