_RUBY_BUILD_URL = "https://github.com/rbenv/ruby-build/archive/refs/tags/v{version}.tar.gz"
_RUBY_INSTALLER_URL = "https://github.com/oneclick/rubyinstaller2/releases/download/RubyInstaller-{version}-1/rubyinstaller-devkit-{version}-1-x64.exe"

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
            url = _RUBY_INSTALLER_URL.format(version = repository_ctx.attr.version),
            output = "ruby-installer.exe",
        )

        repository_ctx.report_progress("Installing Ruby %s" % repository_ctx.attr.version)
        result = repository_ctx.execute([
            "./ruby-installer.exe",
            "/components=ruby,msys2",
            "/dir=dist",
            "/tasks=nomodpath,noassocfiles",
            "/verysilent",
        ])

        repository_ctx.delete("ruby-installer.exe")
    else:
        repository_ctx.report_progress("Downloading ruby-build %s" % repository_ctx.attr.ruby_build_version)
        repository_ctx.download_and_extract(
            url = _RUBY_BUILD_URL.format(version = repository_ctx.attr.ruby_build_version),
            output = "ruby-build",
            stripPrefix = "ruby-build-%s" % repository_ctx.attr.ruby_build_version,
        )

        repository_ctx.report_progress("Installing Ruby %s" % repository_ctx.attr.version)
        result = repository_ctx.execute(["ruby-build/bin/ruby-build", repository_ctx.attr.version, "dist"], timeout = 1200)

        repository_ctx.delete("ruby-build")

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
        "ruby_build_version": attr.string(
            default = "20221101",
        ),
        "_build_tpl": attr.label(
            allow_single_file = True,
            default = "@rules_ruby//:ruby/private/download/BUILD.tpl",
        ),
    },
)
