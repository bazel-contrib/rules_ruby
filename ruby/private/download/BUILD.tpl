load("@rules_ruby//ruby:toolchain.bzl", "rb_toolchain")

package(default_visibility = ["//visibility:public"])

filegroup(
    name = "ruby",
    srcs = select({
        "@platforms//os:windows": ["dist/bin/{ruby_binary_name}.exe"],
        "//conditions:default": ["dist/bin/{ruby_binary_name}"],
    }),
)

filegroup(
    name = "bundle",
    srcs = select({
        "@platforms//os:windows": ["dist/bin/bundle.cmd"],
        "//conditions:default": ["dist/bin/bundle"],
    }),
)

filegroup(
    name = "gem",
    srcs = select({
        "@platforms//os:windows": ["dist/bin/{gem_binary_name}.cmd"],
        "//conditions:default": ["dist/bin/{gem_binary_name}"],
    }),
)

rb_toolchain(
    name = "toolchain",
    bindir = "{bindir}",
    bundle = ":bundle",
    env = {env},
    gem = ":gem",
    ruby = ":ruby",
    version = "{version}",
)

# vim: ft=bzl
