load("@rules_ruby//:ruby.bzl", "rb_binary")
load("@rules_ruby//:ruby.bzl", "rb_library")

package(default_visibility = ["//visibility:public"])

rb_binary(
    name = "rspec-r",
    bin = "{bundle_path}/ruby/2.7.0/bin/rspec",
    deps = [":bundle"]
)

sh_binary(
    name = "rspec-s",
    srcs = ["{bundle_path}/ruby/2.7.0/bin/rspec"],
    deps = [":bundle"]
)

rb_library(
    name = "bundle",
    srcs = glob(["{bundle_path}/**/*"])
)
