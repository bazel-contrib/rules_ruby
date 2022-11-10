load("@io_bazel_stardoc//stardoc:stardoc.bzl", "stardoc")

stardoc(
    name = "rules",
    input = "//ruby:defs.bzl",
    out = "rules.md",
    deps = ["//:ruby"]
)

stardoc(
    name = "repository_rules",
    out = "repository_rules.md",
    input = "//ruby:deps.bzl",
    deps = ["//:ruby"]
)
