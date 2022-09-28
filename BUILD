load("@rules_ruby//:ruby.bzl", "rb_toolchain")

exports_files(["gem_builder.rb.tpl"])
exports_files(glob(['dist/bin/*']))

toolchain_type(
    name = "toolchain_type",
    visibility = ["//visibility:public"],
)

rb_toolchain(
    name = "toolchain",
    ruby = "dist/bin/ruby",
    bundle = "dist/bin/bundle",
)
