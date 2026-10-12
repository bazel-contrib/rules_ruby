load("@rules_ruby//ruby:defs.bzl", "rb_gem_build")

package(default_visibility = ["//:__subpackages__"])

config_setting(
    name = "stamp",
    values = {"stamp": "true"},
)

rb_gem_build(
    name = "gem-build",
    gemspec = "greeter.gemspec",
    deps = ["//lib:greeter"],
)
