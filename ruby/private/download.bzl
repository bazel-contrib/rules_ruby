"Repository rule for fetching Ruby interpreters"

_JRUBY_BINARY_URL = "https://repo1.maven.org/maven2/org/jruby/jruby-dist/{version}/jruby-dist-{version}-bin.tar.gz"
_RUBY_BUILD_URL = "https://github.com/rbenv/ruby-build/archive/refs/tags/v{version}.tar.gz"
_RUBY_INSTALLER_URL = "https://github.com/oneclick/rubyinstaller2/releases/download/RubyInstaller-{version}-1/rubyinstaller-devkit-{version}-1-x64.exe"

# Maintained JRuby versions integrity from https://repo1.maven.org/maven2/org/jruby/jruby-dist.
# Run the following script to update the list:
# ruby -rjson -rnet/http -e 'puts ARGV.each_with_object({}) { |v, h| h[v] = Net::HTTP.get(URI("https://repo1.maven.org/maven2/org/jruby/jruby-dist/#{v}/jruby-dist-#{v}-bin.tar.gz.sha256")) }.to_json' <version>
_JRUBY_VERSIONS = {
    "9.3.0.0": "2dc1f85936d3ff3adc20d90e5f4894499c585a7ea5fedec67154e2f9ecb1bc9b",
    "9.3.1.0": "4a9778c114452c0227e10e6718b2c5e128b310b9c6551be93bdd938888f3c418",
    "9.3.10.0": "c78c127e0aa166f257eeab03c4733ba3d96a445314eff7e5dc1f8154d2b5ae45",
    "9.3.11.0": "655f120c8f29ee81c24b98f2932f6384e317062bcd40720dd8bfef555f97eac9",
    "9.3.12.0": "abe413f1ab7014e3a0d7736619ec02659f07a1f0427c22d4ee9f18e0e4369f61",
    "9.3.13.0": "da60d6cb5c4e4d191abe20448e337b394b27bf0e095133966bcab8ac1191f51d",
    "9.3.14.0": "04c482511d497f41c335345247ee52985be9a8174c042e306dc4c24fac81a9f9",
    "9.3.2.0": "26699ca02beeafa8326573c1125c57a5971ba8b94d15f84e6b3baf2594244f33",
    "9.3.3.0": "3da828cbe287d5468507f1c2c42bef6cf34bc5361bcd6a5d99c207b21b9fdc5c",
    "9.3.4.0": "531544d327a87155d8c804f153a2df3cf04f0182561cb2dd2c9372f48605b65c",
    "9.3.5.0": "074850cee0fb827a52b7805150275edf0421a9cf08895fb76e4d69bcbbd9dc8e",
    "9.3.6.0": "747af6af99a674f208f40da8db22d77c6da493a83280e990b52d523abd9499e2",
    "9.3.7.0": "94a7a8b3beeac2253a8876e73adfac6bececb2b54d2ddfa68f245dc81967d0c1",
    "9.3.8.0": "674a4d1308631faa5f0124d01d73eb1edc89346ee7de21c70e14305bd61b46df",
    "9.3.9.0": "251e6dd8d1d2f82922c8c778d7857e1bef82fe5ca2cf77bc09356421d0b05ab8",
    "9.4.0.0": "897bb8a98ad43adcbf5fd3aa75ec85b3312838c949592ca3f623dc1f569d2870",
    "9.4.1.0": "5e0cce40b7c42f8ad0f619fdd906460fe3ef13444707f70eb8abfc6481e0d6b6",
    "9.4.2.0": "c2b065c5546d398343f86ddea68892bb4a4b4345e6c8875e964a97377733c3f1",
    "9.4.3.0": "b097e08c5669e8a188288e113911d12b4ad2bd67a2c209d6dfa8445d63a4d8c9",
    "9.4.4.0": "6ab12670afd8e5c8ac9305fabe42055795c5ddf9f8e8f1a1e60e260f2d724cc0",
    "9.4.5.0": "a40f78c4641ccc86752e16b2da247fd6bc9fbcf9a4864cf1be36f7ff7b35684c",
    "9.4.6.0": "2da14de4152b71fdbfa35ba4687a46ef12cd465740337b549cc1fe6c7c139813",
    "9.4.7.0": "f1c39f8257505300a528ff83fe4721fbe61a855abb25e3d27d52d43ac97a4d80",
}
_JRUBY_INTEGRITY_MISSING = """

Missing integrity for JRuby {version} ({sha256}).
Please raise an issue at https://github.com/bazel-contrib/rules_ruby.

"""

_BUNDLE_BINSTUB = """#!/usr/bin/env ruby
#
# This file was generated by RubyGems.
#
# The application 'bundler' is installed as part of a gem, and
# this file is here to facilitate running it.
#

require 'rubygems'

version = ">= 0.a"

str = ARGV.first
if str
  str = str.b[/\\A_(.*)_\\z/, 1]
  if str and Gem::Version.correct?(str)
    version = str
    ARGV.shift
  end
end

if Gem.respond_to?(:activate_bin_path)
load Gem.activate_bin_path('bundler', 'bundle', version)
else
gem "bundler", version
load Gem.bin_path("bundler", "bundle", version)
end
"""

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

    kwargs = {}
    sha256 = None
    if version in _JRUBY_VERSIONS:
        sha256 = _JRUBY_VERSIONS[version]
        kwargs["sha256"] = sha256

    download = repository_ctx.download_and_extract(
        url = _JRUBY_BINARY_URL.format(version = version),
        output = "dist/",
        stripPrefix = "jruby-%s" % version,
        **kwargs
    )

    if sha256 != download.sha256:
        print(_JRUBY_INTEGRITY_MISSING.format(sha256 = download.sha256, version = version))  # buildifier: disable=print

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

    # Ruby 3.0 compatibility
    binpath = repository_ctx.path("dist/bin")
    if not binpath.get_child("bundle.cmd").exists:
        repository_ctx.symlink(
            "{}/bundle.bat".format(binpath),
            "{}/bundle.cmd".format(binpath),
        )
    if not binpath.get_child("bundle").exists:
        repository_ctx.file("dist/bin/bundle", _BUNDLE_BINSTUB)

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
            default = "20240423",
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
