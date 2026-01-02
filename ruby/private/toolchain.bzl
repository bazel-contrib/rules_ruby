"Repository rule for registering Ruby interpreters"

load("//ruby/private:download.bzl", _rb_download = "rb_download")
load("//ruby/private/toolchain:repository_proxy.bzl", _rb_toolchain_repository_proxy = "rb_toolchain_repository_proxy")

DEFAULT_RUBY_REPOSITORY = "ruby"

def rb_register_toolchains(
        name = DEFAULT_RUBY_REPOSITORY,
        version = None,
        version_file = None,
        msys2_packages = ["libyaml"],
        checksums = {},
        register = True,
        **kwargs):
    """
    Register a Ruby toolchain and lazily download the Ruby Interpreter.

    * _(For MRI on Linux and macOS)_ Installed using [ruby-build](https://github.com/rbenv/ruby-build).
    * _(For MRI on Windows)_ Installed using [RubyInstaller](https://rubyinstaller.org).
    * _(For JRuby on any OS)_ Downloaded and installed directly from [official website](https://www.jruby.org).
    * _(For TruffleRuby on Linux and macOS)_ Installed using [ruby-build](https://github.com/rbenv/ruby-build).
    * _(For rv-ruby)_ Prebuilt Ruby downloaded from [rv-ruby](https://github.com/spinel-coop/rv-ruby).
    * _(For "system")_ Ruby found on the PATH is used. Please note that builds are not hermetic in this case.

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
        version: a semver version of MRI, or a string like [interpreter type]-[version], or "system".
            For rv-ruby, use format "rv-{release}-{version}" (e.g., "rv-20251225-3.4.5").
        version_file: .ruby-version or .tool-versions file to read version from
        msys2_packages: extra MSYS2 packages to install
        checksums: platform checksums for rv-ruby downloads.
            Keys: linux-x86_64, linux-arm64, macos-arm64, macos-x86_64.
        register: whether to register the resulting toolchains, should be False under bzlmod
        **kwargs: additional parameters to the downloader for this interpreter type
    """
    proxy_repo_name = name + "_toolchains"
    if name not in native.existing_rules().values():
        _rb_download(
            name = name,
            version = version,
            version_file = version_file,
            msys2_packages = msys2_packages,
            checksums = checksums,
            **kwargs
        )
        _rb_toolchain_repository_proxy(
            name = proxy_repo_name,
            toolchain = "@{}//:toolchain".format(name),
            toolchain_type = "@rules_ruby//ruby:toolchain_type",
        )
        if register:
            native.register_toolchains("@{}//:all".format(proxy_repo_name))
