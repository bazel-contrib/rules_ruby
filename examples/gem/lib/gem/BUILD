load("@rules_ruby//:ruby.bzl", "rb_binary")
load("@rules_ruby//:ruby.bzl", "rb_library")

package(default_visibility = ["//:__subpackages__"])

rb_library(
    name = "add",
    srcs = ["add.rb"],
)

rb_library(
    name = "subtract",
    srcs = ["subtract.rb"],
)

rb_library(
    name = "version",
    srcs = ["version.rb"],
)

rb_binary(
    name = "print-version",
    args = ["lib/gem/version.rb"],
    deps = [":version"]
)
