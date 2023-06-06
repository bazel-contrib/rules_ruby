_JRUBY_BINARY_URL = "https://repo1.maven.org/maven2/org/jruby/jruby-dist/{version}/jruby-dist-{version}-bin.tar.gz"
_RUBY_BUILD_URL = "https://github.com/rbenv/ruby-build/archive/refs/tags/v{version}.tar.gz"
_RUBY_INSTALLER_URL = "https://github.com/oneclick/rubyinstaller2/releases/download/RubyInstaller-{version}-1/rubyinstaller-devkit-{version}-1-x64.exe"

def rb_download(**kwargs):
    """
    Downloads an Ruby interpreter and registers it toolchain.

    * _(For MRI on Linux and macOS)_ Installed using [ruby-build](https://github.com/rbenv/ruby-build).
    * _(For MRI on Windows)_ Installed using [RubyInstaller](https://rubyinstaller.org).
    * _(For JRuby on any OS)_ Downloaded and installed directly from [official website](https://www.jruby.org).
    * _(For TruffleRuby on Linux and macOS)_ Installed using [ruby-build](https://github.com/rbenv/ruby-build).

    `WORKSPACE`:
    ```bazel
    load("@rules_ruby//ruby:deps.bzl", "rb_download")

    rb_download(
        version = "2.7.5"
    )
    ```
    """
    _rb_download(
        name = "rules_ruby_dist",
        **kwargs
    )
    native.register_toolchains("@rules_ruby_dist//:toolchain")

def _rb_download_impl(repository_ctx):
    if repository_ctx.attr.version.startswith("jruby"):
        _install_jruby(repository_ctx)
    elif repository_ctx.os.name.startswith("windows"):
        _install_via_rubyinstaller(repository_ctx)
    else:
        _install_via_ruby_build(repository_ctx)

    if repository_ctx.attr.version.startswith("jruby"):
        ruby_binary_name = "jruby"
        gem_binary_name = "jgem"
    else:
        ruby_binary_name = "ruby"
        gem_binary_name = "gem"

    repository_ctx.template(
        "BUILD",
        repository_ctx.attr._build_tpl,
        executable = False,
        substitutions = {
            "{bindir}": repr(repository_ctx.path("dist/bin")),
            "{version}": repository_ctx.attr.version,
            "{ruby_binary_name}": ruby_binary_name,
            "{gem_binary_name}": gem_binary_name,
        },
    )

def _install_jruby(repository_ctx):
    version = repository_ctx.attr.version.removeprefix("jruby-")
    repository_ctx.report_progress("Downloading JRuby %s" % version)
    repository_ctx.download_and_extract(
        url = _JRUBY_BINARY_URL.format(version = version),
        output = "dist/",
        stripPrefix = "jruby-%s" % version,
    )

    if repository_ctx.os.name.startswith("windows"):
        repository_ctx.symlink("dist/bin/bundle.bat", "dist/bin/bundle.cmd")

def _install_via_rubyinstaller(repository_ctx):
    repository_ctx.report_progress("Downloading RubyInstaller")
    repository_ctx.download(
        url = _RUBY_INSTALLER_URL.format(version = repository_ctx.attr.version),
        output = "ruby-installer.exe",
    )

    repository_ctx.report_progress("Installing Ruby %s" % repository_ctx.attr.version)
    result = repository_ctx.execute([
        "./ruby-installer.exe",
        "/components=ruby,msys2",
        "/currentuser",
        "/dir=dist",
        "/tasks=nomodpath,noassocfiles",
        "/verysilent",
    ])

    repository_ctx.delete("ruby-installer.exe")

    if result.return_code != 0:
        fail("%s\n%s" % (result.stdout, result.stderr))

    binpath = repository_ctx.path("dist/bin")
    if not binpath.get_child("bundle.cmd").exists:
        repository_ctx.symlink(
            "{}/bundle.bat".format(binpath),
            "{}/bundle.cmd".format(binpath),
        )

def _install_via_ruby_build(repository_ctx):
    repository_ctx.report_progress("Downloading ruby-build %s" % repository_ctx.attr.ruby_build_version)
    repository_ctx.download_and_extract(
        url = _RUBY_BUILD_URL.format(version = repository_ctx.attr.ruby_build_version),
        output = "ruby-build",
        stripPrefix = "ruby-build-%s" % repository_ctx.attr.ruby_build_version,
    )

    repository_ctx.report_progress("Installing Ruby %s" % repository_ctx.attr.version)
    result = repository_ctx.execute(
        ["ruby-build/bin/ruby-build", "--verbose", repository_ctx.attr.version, "dist"],
        timeout = 1200,
        quiet = not repository_ctx.os.environ.get("RUBY_RULES_DEBUG", default = False),
    )

    repository_ctx.delete("ruby-build")

    if result.return_code != 0:
        fail("%s\n%s" % (result.stdout, result.stderr))

_rb_download = repository_rule(
    implementation = _rb_download_impl,
    attrs = {
        "version": attr.string(
            mandatory = True,
            doc = """
Ruby version to install.
            """,
        ),
        "ruby_build_version": attr.string(
            default = "20230428",
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
)
