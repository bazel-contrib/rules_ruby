"Public API for repository rules"

load("//ruby/private:bundle.bzl", _rb_bundle = "rb_bundle")
load("//ruby/private:bundle_fetch.bzl", _rb_bundle_fetch = "rb_bundle_fetch")
load("//ruby/private:toolchain.bzl", _rb_register_toolchains = "rb_register_toolchains")

def rb_bundle(toolchain = "@ruby//:BUILD", **kwargs):
    """
    Wraps `rb_bundle_rule()` providing default toolchain name.

    Args:
      toolchain: default Ruby toolchain BUILD
      **kwargs: underlying attrs passed to rb_bundle_rule()
    """
    _rb_bundle(
        toolchain = toolchain,
        **kwargs
    )

rb_register_toolchains = _rb_register_toolchains
rb_bundle_fetch = _rb_bundle_fetch
rb_bundle_rule = _rb_bundle
