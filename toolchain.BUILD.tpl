load("@rules_ruby//:ruby.bzl", "rb_toolchain")

filegroup(
    name = "ruby",
    srcs = select({
        "@platforms//os:windows": ["dist/bin/ruby.exe"],
        "//conditions:default": ["dist/bin/ruby"],
    }),
)

filegroup(
    name = "bundle",
    srcs = select({
        "@platforms//os:windows": ["dist/bin/bundle.cmd"],
        "//conditions:default": ["dist/bin/bundle"],
    }),
)

toolchain_type(
    name = "toolchain_type",
    visibility = ["//visibility:public"],
)

rb_toolchain(
    name = "toolchain",
    ruby = ":ruby",
    bundle = ":bundle",
    bindir = "{bindir}",
)
