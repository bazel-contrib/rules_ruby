load("@rules_ruby//:ruby.bzl", "rb_toolchain")

exports_files(glob(['bin/*']))

toolchain_type(
    name = "toolchain_type",
    visibility = ["//visibility:public"],
)

rb_toolchain(
    name = "toolchain",
    ruby = "bin/ruby",
    bundle = "bin/bundle",
)
