"Public API for repository rules"

load("//ruby/private:bundle.bzl", _rb_bundle = "rb_bundle")
load("//ruby/private:download.bzl", _rb_register_toolchains = "rb_register_toolchains")

def rb_bundle(toolchain = "@rules_ruby_dist//:BUILD", **kwargs):
    _rb_bundle(
        toolchain = toolchain,
        **kwargs
    )

rb_register_toolchains = _rb_register_toolchains
