"Public API for repository rules"

load("//ruby/private:bundle_fetch.bzl", _rb_bundle_fetch = "rb_bundle_fetch")
load("//ruby/private:toolchain.bzl", _rb_register_toolchains = "rb_register_toolchains")

rb_register_toolchains = _rb_register_toolchains
rb_bundle_fetch = _rb_bundle_fetch
