load("@rules_ruby//ruby:defs.bzl", "rb_binary", "rb_library")

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
    args = [
        "lib/gem/add.rb",
        "1",  # pass 1 argument here and 1 extra in CI
    ],
    deps = [":add"],
)

rb_binary(
    name = "print-version",
    args = ["lib/gem/version.rb"],
    deps = [":version"],
)
