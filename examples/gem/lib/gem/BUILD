load("@rules_ruby//ruby:defs.bzl", "rb_binary", "rb_library")
load("@bazel_skylib//rules:run_binary.bzl", "run_binary")

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
    name = "add-numbers",
    args = ["1"],  # pass 1 argument here and 1 extra in CI
    main = "add.rb",
    deps = [
        ":add",
        "@bundle",
    ],
)

rb_binary(
    name = "print-version",
    args = ["lib/gem/version.rb"],
    deps = [":version"],
)

run_binary(
    name = "perform-addition",
    tool = ":add-numbers",
    args = ["1", "2"],
    outs = ["out"],
)