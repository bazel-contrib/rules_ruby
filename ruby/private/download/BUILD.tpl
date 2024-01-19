load("@rules_ruby//ruby:defs.bzl", "rb_binary")
load("@rules_ruby//ruby:toolchain.bzl", "rb_toolchain")

package(default_visibility = ["//visibility:public"])

filegroup(
    name = "ruby_file",
    srcs = select({
        "@platforms//os:windows": ["dist/bin/{ruby_binary_name}.exe"],
        "//conditions:default": ["dist/bin/{ruby_binary_name}"],
    }),
)

rb_binary(
    name = "ruby",
    main = ":ruby_file",
)

rb_toolchain(
    name = "toolchain",
    bundle = select({
        "@platforms//os:windows": "dist/bin/bundle.cmd",
        "//conditions:default": "dist/bin/bundle",
    }),
    env = {env},
    files = glob(["dist/**/*"]),
    gem = select({
        "@platforms//os:windows": "dist/bin/{gem_binary_name}.cmd",
        "//conditions:default": "dist/bin/{gem_binary_name}",
    }),
    ruby = ":ruby_file",
    version = "{version}",
)

[
    rb_binary(
        name = file.removeprefix("dist/bin/"),
        main = file,
    )
    for file in glob(
        ["dist/bin/*"],
        exclude = [
            "dist/bin/ruby",
            "dist/bin/jruby",
        ] + glob([
            "dist/bin/*.exe",
        ], allow_empty = True) + glob([
            "dist/bin/*.cmd",
        ], allow_empty = True) + glob([
            "dist/bin/*.bat",
        ], allow_empty = True),
    )
]

# vim: ft=bzl
