load("@rules_ruby//:ruby.bzl", "rb_binary")
load("@rules_ruby//:ruby.bzl", "rb_library")

package(default_visibility = ["//visibility:public"])

rb_library(
    name = "bundle",
    srcs = glob(["**/*"])
)
