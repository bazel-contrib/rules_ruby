load("@bazel_skylib//rules:expand_template.bzl", "expand_template")
load("@rules_ruby//ruby:defs.bzl", "rb_library")
load("//:version.bzl", "UNSTAMPED_VERSION", "VERSION")

expand_template(
    name = "version_rb",
    out = "greeter/version.rb",
    substitutions = select({
        "//:stamp": {"{VERSION}": VERSION},
        "//conditions:default": {"{VERSION}": UNSTAMPED_VERSION},
    }),
    template = "greeter/version.rb.tpl",
    # Staged into @bundle at build time.
    visibility = ["//visibility:public"],
)

rb_library(
    name = "greeter",
    srcs = [
        "greeter.rb",
        ":version_rb",
    ],
    visibility = ["//:__subpackages__"],
)
