"Repository rule for fetching Ruby interpreters"

_JRUBY_BINARY_URL = "https://repo1.maven.org/maven2/org/jruby/jruby-dist/{version}/jruby-dist-{version}-bin.tar.gz"
_RUBY_BUILD_URL = "https://github.com/rbenv/ruby-build/archive/refs/tags/v{version}.tar.gz"
_RUBY_INSTALLER_URL = "https://github.com/oneclick/rubyinstaller2/releases/download/RubyInstaller-{version}-1/rubyinstaller-devkit-{version}-1-x64.exe"

def _rb_download_impl(repository_ctx):
    if repository_ctx.attr.version and not repository_ctx.attr.version_file:
        version = repository_ctx.attr.version
    elif repository_ctx.attr.version_file and not repository_ctx.attr.version:
        version = _read_version_from_file(repository_ctx)
    elif repository_ctx.attr.version_file and repository_ctx.attr.version:
        fail("only one of mandatory attributes 'version' or 'version_file' is allowed")
    else:
        fail("missing value for one of mandatory attributes 'version' or 'version_file'")

    if version.startswith("jruby"):
        _install_jruby(repository_ctx, version)
    elif version == "system":
        _symlink_system_ruby(repository_ctx)
    elif repository_ctx.os.name.startswith("windows"):
        _install_via_rubyinstaller(repository_ctx, version)
    else:
        _install_via_ruby_build(repository_ctx, version)

    if version.startswith("jruby"):
        ruby_binary_name = "jruby"
        gem_binary_name = "jgem"
    else:
        ruby_binary_name = "ruby"
        gem_binary_name = "gem"

    env = {}
    if version.startswith("jruby"):
        # JRuby might fail with "Errno::EACCES: Permission denied - NUL" on Windows:
        # https://github.com/jruby/jruby/issues/7182#issuecomment-1112953015
        env.update({"JAVA_OPTS": "-Djdk.io.File.enableADS=true"})
    elif version.startswith("truffleruby"):
        # TruffleRuby needs explicit locale
        # https://www.graalvm.org/dev/reference-manual/ruby/UTF8Locale/
        env.update({"LANG": "en_US.UTF-8"})

    repository_ctx.template(
        "BUILD",
        repository_ctx.attr._build_tpl,
        executable = False,
        substitutions = {
            "{bindir}": repr(repository_ctx.path("dist/bin")),
            "{version}": version,
            "{ruby_binary_name}": ruby_binary_name,
            "{gem_binary_name}": gem_binary_name,
            "{env}": repr(env),
        },
    )

def _read_version_from_file(repository_ctx):
    version = repository_ctx.read(repository_ctx.attr.version_file).strip("\r\n")
    if repository_ctx.attr.version_file.name == ".tool-versions":
        return _parse_version_from_tool_versions(version)
    else:
        return version

def _parse_version_from_tool_versions(file):
    for line in file.splitlines():
        if line.startswith("ruby"):
            version = line.partition(" ")[-1]
            return version
    return None

def _install_jruby(repository_ctx, version):
    version = version.removeprefix("jruby-")
    repository_ctx.report_progress("Downloading JRuby %s" % version)
    repository_ctx.download_and_extract(
        url = _JRUBY_BINARY_URL.format(version = version),
        output = "dist/",
        stripPrefix = "jruby-%s" % version,
    )

    if repository_ctx.os.name.startswith("windows"):
        repository_ctx.symlink("dist/bin/bundle.bat", "dist/bin/bundle.cmd")
        repository_ctx.symlink("dist/bin/jgem.bat", "dist/bin/jgem.cmd")

# https://github.com/oneclick/rubyinstaller2/wiki/FAQ#q-how-do-i-perform-a-silentunattended-install-with-the-rubyinstaller
def _install_via_rubyinstaller(repository_ctx, version):
    repository_ctx.report_progress("Downloading RubyInstaller")
    repository_ctx.download(
        url = _RUBY_INSTALLER_URL.format(version = version),
        output = "ruby-installer.exe",
    )

    repository_ctx.report_progress("Installing Ruby %s" % version)
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

    result = repository_ctx.execute(["./dist/bin/ridk.cmd", "install", "1", "3"])
    if result.return_code != 0:
        fail("%s\n%s" % (result.stdout, result.stderr))

    if len(repository_ctx.attr.msys2_packages) > 0:
        mingw_package_prefix = None
        result = repository_ctx.execute([
            "./dist/bin/ruby.exe",
            "-rruby_installer",
            "-e",
            "puts RubyInstaller::Runtime::Msys2Installation.new.mingw_package_prefix",
        ])
        if result.return_code != 0:
            fail("%s\n%s" % (result.stdout, result.stderr))
        else:
            mingw_package_prefix = result.stdout.strip()

        packages = ["%s-%s" % (mingw_package_prefix, package) for package in repository_ctx.attr.msys2_packages]
        result = repository_ctx.execute(["./dist/bin/ridk.cmd", "exec", "pacman", "--sync", "--noconfirm"] + packages)
        if result.return_code != 0:
            fail("%s\n%s" % (result.stdout, result.stderr))

    binpath = repository_ctx.path("dist/bin")
    if not binpath.get_child("bundle.cmd").exists:
        repository_ctx.symlink(
            "{}/bundle.bat".format(binpath),
            "{}/bundle.cmd".format(binpath),
        )

def _install_via_ruby_build(repository_ctx, version):
    repository_ctx.report_progress("Downloading ruby-build %s" % repository_ctx.attr.ruby_build_version)
    repository_ctx.download_and_extract(
        url = _RUBY_BUILD_URL.format(version = repository_ctx.attr.ruby_build_version),
        output = "ruby-build",
        stripPrefix = "ruby-build-%s" % repository_ctx.attr.ruby_build_version,
    )

    repository_ctx.report_progress("Installing Ruby %s" % version)
    result = repository_ctx.execute(
        ["ruby-build/bin/ruby-build", "--verbose", version, "dist"],
        timeout = 1200,
        quiet = not repository_ctx.os.environ.get("RUBY_RULES_DEBUG", default = False),
    )

    repository_ctx.delete("ruby-build")

    if result.return_code != 0:
        fail("%s\n%s" % (result.stdout, result.stderr))

def _symlink_system_ruby(repository_ctx):
    ruby = repository_ctx.which("ruby")
    repository_ctx.symlink(ruby.dirname, "dist/bin")
    if repository_ctx.os.name.startswith("windows"):
        repository_ctx.symlink(ruby.dirname.dirname.get_child("lib"), "dist/lib")

rb_download = repository_rule(
    implementation = _rb_download_impl,
    attrs = {
        "version": attr.string(
            doc = "Ruby version to install.",
        ),
        "version_file": attr.label(
            allow_single_file = [".ruby-version"],
            doc = "File to read Ruby version from.",
        ),
        "msys2_packages": attr.string_list(
            default = ["libyaml"],
            doc = """
Extra MSYS2 packages to install.

By default, contains `libyaml` (dependency of a `psych` gem).
""",
        ),
        "ruby_build_version": attr.string(
            default = "20231225",
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
