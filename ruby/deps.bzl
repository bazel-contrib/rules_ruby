load("//ruby/private:bundle.bzl", _rb_bundle = "rb_bundle")
load("//ruby/private:download.bzl", _rb_download = "rb_download", _rb_register_toolchains = "rb_register_toolchains")

rb_bundle = _rb_bundle
rb_register_toolchains = _rb_register_toolchains
rb_download = _rb_download
