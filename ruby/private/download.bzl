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

        binpath = repository_ctx.path("dist/bin")
        if not binpath.get_child("bundle.cmd").exists:
            repository_ctx.symlink(
                "{}/bundle.bat".format(binpath),
                "{}/bundle.cmd".format(binpath),
            )
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
            doc = """
Ruby version to install.

On Linux and macOS, the version is one of the
[ruby-build](https://github.com/rbenv/ruby-build/tree/master/share/ruby-build) versions.

On Windows, the version is one of [RubyInstaller](https://rubyinstaller.org) versions.
            """,
        ),
        "ruby_build_version": attr.string(
            default = "20221225",
            doc = """
Version of [ruby-build](https://github.com/rbenv/ruby-build/releases)
to install. You normally don't need to change this, unless `version` you pass is a new one
which isn't available in this ruby-build yet.
            """,
        ),
        "_build_tpl": attr.label(
            allow_single_file = True,
            default = "@rules_ruby//:ruby/private/download/BUILD.tpl",
        ),
    },
    doc = """
Downloads an Ruby interpreter and registers it toolchain.

On Linux and macOS, Ruby is installed using [ruby-build](https://github.com/rbenv/ruby-build)
and supports variety of interpreters (MRI, JRuby, TruffleRuby and others).

On Windows, Ruby is installed using [RubyInstaller](https://rubyinstaller.org)
and supports only MRI at the moment.

`WORKSPACE`:
```bazel
load("@rules_ruby//ruby:deps.bzl", "rb_download")

rb_download(
    version = "2.7.5"
)
```
    """,
)
