"Repository rule for registering Ruby interpreters"

load("//ruby/private:download.bzl", _rb_download = "rb_download")
load("//ruby/private/toolchain:repository_proxy.bzl", _rb_toolchain_repository_proxy = "rb_toolchain_repository_proxy")

DEFAULT_RUBY_REPOSITORY = "ruby"

def rb_register_toolchains(name = DEFAULT_RUBY_REPOSITORY, version = None, version_file = None, register = True, **kwargs):
    """
    Register a Ruby toolchain and lazily download the Ruby Interpreter.

    * _(For MRI on Linux and macOS)_ Installed using [ruby-build](https://github.com/rbenv/ruby-build).
    * _(For MRI on Windows)_ Installed using [RubyInstaller](https://rubyinstaller.org).
    * _(For JRuby on any OS)_ Downloaded and installed directly from [official website](https://www.jruby.org).
    * _(For TruffleRuby on Linux and macOS)_ Installed using [ruby-build](https://github.com/rbenv/ruby-build).
    * _(For "system") Ruby found on the PATH is used. Please note that builds are not hermetic in this case.

    `WORKSPACE`:
    ```bazel
    load("@rules_ruby//ruby:deps.bzl", "rb_register_toolchains")

    rb_register_toolchains(
        version = "3.0.6"
    )
    ```

    Args:
        name: base name of resulting repositories, by default "rules_ruby"
        version: a semver version of MRI, or a string like [interpreter type]-[version], or "system"
        version_file: .ruby-version or .tool-versions file to read version from
        register: whether to register the resulting toolchains, should be False under bzlmod
        **kwargs: additional parameters to the downloader for this interpreter type
    """
    proxy_repo_name = name + "_toolchains"
    if name not in native.existing_rules().values():
        _rb_download(
            name = name,
            version = version,
            version_file = version_file,
            **kwargs
        )
        _rb_toolchain_repository_proxy(
            name = proxy_repo_name,
            toolchain = "@{}//:toolchain".format(name),
            toolchain_type = "@rules_ruby//ruby:toolchain_type",
        )
        if register:
            native.register_toolchains("@{}//:all".format(proxy_repo_name))
