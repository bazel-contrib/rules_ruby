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
        register = True,
        **kwargs):
    """
    Register a Ruby toolchain and lazily download the Ruby Interpreter.

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

    `WORKSPACE`:
    ```bazel
    load("@rules_ruby//ruby:deps.bzl", "rb_register_toolchains")

    rb_register_toolchains(
        version = "3.0.6"
    )
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
        register: whether to register the resulting toolchains, should be False under bzlmod
        **kwargs: additional parameters to the downloader for this interpreter type
    """
    proxy_repo_name = name + "_toolchains"

    # Multi-platform mode is only meaningful for CRuby + portable_ruby. JRuby's
    # archive is platform-independent, TruffleRuby and "system" can't cross-
    # compile, and Windows CRuby goes through RubyInstaller (handled per
    # per-platform repo). When we can't determine the engine ahead of time
    # (e.g. WORKSPACE mode with version_file but no module_ctx to read it), we
    # fall back to single-platform host-only.
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
            if per_repo not in native.existing_rules():
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
        if name not in native.existing_rules():
            _rb_hub_repository(
                name = name,
                apparent_name = name,
                platforms = MULTI_PLATFORM_RUBY_PLATFORMS,
                engine = "ruby",
            )
        if proxy_repo_name not in native.existing_rules():
            _rb_toolchain_repository_proxy(
                name = proxy_repo_name,
                toolchains = entries,
                toolchain_type = _TOOLCHAIN_TYPE,
            )
    else:
        if name not in native.existing_rules():
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
        if proxy_repo_name not in native.existing_rules():
            _rb_toolchain_repository_proxy(
                name = proxy_repo_name,
                toolchains = ["{}|".format(name)],
                toolchain_type = _TOOLCHAIN_TYPE,
            )

    if register:
        native.register_toolchains("@{}//:all".format(proxy_repo_name))
