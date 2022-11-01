load("@rules_ruby//ruby:toolchain.bzl", "rb_toolchain")

package(default_visibility = ["//visibility:public"])

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
)

rb_toolchain(
    name = "toolchain",
    ruby = ":ruby",
    bundle = ":bundle",
    bindir = "{bindir}",
)
