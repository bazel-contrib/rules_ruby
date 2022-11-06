load("@rules_ruby//ruby:defs.bzl", "rb_binary", "rb_library", "rb_gem_build", "rb_gem_push")

package(default_visibility = ["//:__subpackages__"])

rb_library(
    name = "gem",
    srcs = ["Gemfile", "Gemfile.lock", "gem.gemspec"],
    deps = ["//lib:gem"]
)

rb_binary(
    name = "rubocop",
    bin = "@bundle//:bin/rubocop",
    args = ["lib"],
    deps = [
        ":gem",
        "@bundle"
    ]
)

rb_gem_build(
    name = "example",
    gemspec = "gem.gemspec",
    deps = [":gem"],
)

rb_gem_push(
    name = "example-release",
    src = ":example",
)
