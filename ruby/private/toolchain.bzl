"Repository rule for registering Ruby interpreters"

load("//ruby/private:download.bzl", _rb_download = "rb_download")
load("//ruby/private/toolchain:hub.bzl", _rb_hub_repository = "rb_hub_repository")
load("//ruby/private/toolchain:platforms.bzl", "MULTI_PLATFORM_RUBY_PLATFORMS")
load("//ruby/private/toolchain:repository_proxy.bzl", _rb_toolchain_repository_proxy = "rb_toolchain_repository_proxy")

DEFAULT_RUBY_REPOSITORY = "ruby"

_TOOLCHAIN_TYPE = "@rules_ruby//ruby:toolchain_type"

def rb_register_toolchains(
        name = DEFAULT_RUBY_REPOSITORY,
        version = None,
        version_file = None,
        msys2_packages = ["libyaml"],
        portable_ruby = False,
        portable_ruby_release_suffix = "",
        portable_ruby_checksums = {},
        resolved_version = None,
        **kwargs):
    """
    Create Ruby toolchain repositories and lazily download the Ruby interpreter.

    Use the Ruby module extension to create these repositories, then register
    the toolchains in `MODULE.bazel`.

    * _(For MRI on Linux and macOS)_ Installed using [ruby-build](https://github.com/rbenv/ruby-build).
    * _(For MRI on Windows)_ Installed using [RubyInstaller](https://rubyinstaller.org).
    * _(For JRuby on any OS)_ Downloaded and installed directly from [official website](https://www.jruby.org).
    * _(For TruffleRuby on Linux and macOS)_ Installed using [ruby-build](https://github.com/rbenv/ruby-build).
    * _(With portable_ruby)_ Portable Ruby downloaded from [bazel-contrib/portable-ruby](https://github.com/bazel-contrib/portable-ruby).
    * _(For "system")_ Ruby found on the PATH is used. Please note that builds are not hermetic in this case.

    When `portable_ruby = True`, this function registers a Bazel toolchain per
    supported execution platform so that builds resolve to the right
    interpreter on remote execution and cross-platform setups. Per-platform
    repositories `@<name>_<platform>` are created lazily — Bazel only fetches
    the one matching the resolved exec platform. A hub repository `@<name>`
    aliases the canonical targets (`:bundle`, `:gem`, `:ruby`, `:headers`,
    `:jars`, etc.) via `select()`, preserving direct references like
    `@ruby//:bundle`.

    JRuby's archive is platform-independent (JVM-based), so it is registered
    as a single unconstrained toolchain — no per-platform repos needed.

    Other modes (ruby-build for MRI source compile, TruffleRuby, RubyInstaller,
    `system`) remain single-platform host-only.

    `MODULE.bazel`:
    ```bazel
    ruby = use_extension("@rules_ruby//ruby:extensions.bzl", "ruby")

    ruby.toolchain(
        name = "ruby",
        version = "3.4.11",
    )
    use_repo(ruby, "ruby", "ruby_toolchains")

    register_toolchains("@ruby_toolchains//:all")
    ```

    Once registered, you can use the toolchain directly as it provides all the binaries:

    ```output
    $ bazel run @ruby -- -e "puts RUBY_VERSION"
    $ bazel run @ruby//:bundle -- update
    $ bazel run @ruby//:gem -- install rails
    ```

    You can also use Ruby engine targets to `select()` depending on installed Ruby interpreter:

    `BUILD`:
    ```bazel
    rb_library(
        name = "my_lib",
        srcs = ["my_lib.rb"],
        deps = select({
            "@ruby//engine:jruby": [":my_jruby_lib"],
            "@ruby//engine:truffleruby": ["//:my_truffleruby_lib"],
            "@ruby//engine:ruby": ["//:my__lib"],
            "//conditions:default": [],
        }),
    )
    ```

    Args:
        name: base name of resulting repositories, by default "ruby"
        version: a semver version of MRI, or a string like [interpreter type]-[version], or "system"
        version_file: .ruby-version or .tool-versions file to read version from
        msys2_packages: extra MSYS2 packages to install
        portable_ruby: when True, downloads portable Ruby from bazel-contrib/portable-ruby instead of compiling
            via ruby-build. Has no effect on JRuby, TruffleRuby, or Windows.
        portable_ruby_release_suffix: release suffix for portable Ruby (default "1", e.g. "2" downloads X.Y.Z-2).
        portable_ruby_checksums: platform checksums for portable Ruby downloads, overriding
            built-in checksums.
        resolved_version: the version string resolved from `version_file` by the module
            extension. Used to detect JRuby (which skips the multi-platform `portable_ruby`
            path since its archive is platform-independent).
        **kwargs: additional parameters to the downloader for this interpreter type
    """
    proxy_repo_name = name + "_toolchains"

    # Multi-platform mode is only meaningful for MRI + portable_ruby. JRuby's
    # archive is platform-independent, TruffleRuby and "system" can't cross-
    # compile, and Windows MRI goes through RubyInstaller (handled per
    # per-platform repo). The module extension resolves version_file before
    # creating the repositories.
    effective_version = resolved_version if resolved_version != None else version
    is_jruby = effective_version != None and effective_version.startswith("jruby")
    is_truffleruby = effective_version != None and effective_version.startswith("truffleruby")
    is_system = effective_version == "system"
    use_multi_platform = (
        portable_ruby and
        effective_version != None and
        not is_jruby and
        not is_truffleruby and
        not is_system
    )

    if use_multi_platform:
        entries = []
        for plat in MULTI_PLATFORM_RUBY_PLATFORMS:
            per_repo = "{}_{}".format(name, plat)
            _rb_download(
                name = per_repo,
                version = version,
                version_file = version_file,
                msys2_packages = msys2_packages,
                portable_ruby = portable_ruby,
                portable_ruby_release_suffix = portable_ruby_release_suffix,
                portable_ruby_checksums = portable_ruby_checksums,
                platform = plat,
                **kwargs
            )
            entries.append("{}|{}".format(per_repo, plat))
        _rb_hub_repository(
            name = name,
            apparent_name = name,
            platforms = MULTI_PLATFORM_RUBY_PLATFORMS,
            engine = "ruby",
        )
        _rb_toolchain_repository_proxy(
            name = proxy_repo_name,
            toolchains = entries,
            toolchain_type = _TOOLCHAIN_TYPE,
        )
    else:
        _rb_download(
            name = name,
            version = version,
            version_file = version_file,
            msys2_packages = msys2_packages,
            portable_ruby = portable_ruby,
            portable_ruby_release_suffix = portable_ruby_release_suffix,
            portable_ruby_checksums = portable_ruby_checksums,
            **kwargs
        )
        _rb_toolchain_repository_proxy(
            name = proxy_repo_name,
            toolchains = ["{}|".format(name)],
            toolchain_type = _TOOLCHAIN_TYPE,
        )
