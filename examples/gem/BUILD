load(
    "@rules_ruby//ruby:defs.bzl",
    "rb_binary",
    "rb_gem_build",
    "rb_gem_push",
    "rb_library",
)

package(default_visibility = ["//:__subpackages__"])

rb_library(
    name = "gem",
    srcs = [
        "Gemfile",
        "Gemfile.lock",
        "gem.gemspec",
    ],
    deps = ["//lib:gem"],
)

rb_binary(
    name = "rubocop",
    args = ["lib"],
    main = "@bundle//:bin/rubocop",
    deps = [
        ":gem",
        "@bundle",
    ],
)

rb_gem_build(
    name = "gem-build",
    gemspec = "gem.gemspec",
    deps = [":gem"],
)

rb_gem_push(
    name = "gem-release",
    src = ":gem-build",
)
