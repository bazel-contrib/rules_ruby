load("@buildifier_prebuilt//:rules.bzl", "buildifier")
load("@gazelle//:def.bzl", "gazelle", "gazelle_binary")

gazelle_binary(
    name = "gazelle_bin",
    languages = ["@bazel_skylib_gazelle_plugin//bzl"],
)

gazelle(
    name = "gazelle",
    gazelle = "gazelle_bin",
)

buildifier(
    name = "buildifier",
    exclude_patterns = ["./.git/*"],
    lint_mode = "fix",
)

buildifier(
    name = "buildifier.check",
    diff_command = "diff -u",
    exclude_patterns = ["./.git/*"],
    lint_mode = "warn",
    mode = "diff",
)
