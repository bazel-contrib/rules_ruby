load("//ruby/private:bundle.bzl", _rb_bundle = "rb_bundle")
load("//ruby/private:download.bzl", _rb_download = "rb_download")

rb_bundle = _rb_bundle
rb_register_toolchains = _rb_download
rb_download = _rb_download # backwards-compatibility
