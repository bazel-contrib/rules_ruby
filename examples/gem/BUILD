load(
    "@rules_ruby//ruby:defs.bzl",
    "rb_binary",
    "rb_gem_build",
    "rb_gem_push",
    "rb_library",
    "rb_test",
)

package(default_visibility = ["//:__subpackages__"])

rb_binary(
    name = "rake",
    main = "@bundle//:bin/rake",
    deps = [
        "//lib:gem",
        "@bundle",
    ],
)

rb_test(
    name = "rubocop",
    size = "small",
    data = [".rubocop.yml"],
    main = "@bundle//:bin/rubocop",
    tags = ["no-sandbox"],
    deps = [
        "//lib:gem",
        "//spec:add",
        "//spec:env",
        "//spec:file",
        "//spec:subtract",
        "@bundle",
    ],
)

rb_gem_build(
    name = "gem-build",
    gemspec = "gem.gemspec",
    deps = [
        "//lib:gem",
        "@bundle",
    ],
)

rb_gem_push(
    name = "gem-release",
    gem = ":gem-build",
)
