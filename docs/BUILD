# This load statement must be in the docs/ package rather than anything users depend on
# so that the dependency on stardoc doesn't leak to them.
load("@aspect_bazel_lib//lib:docs.bzl", "stardoc_with_diff_test", "update_docs")

stardoc_with_diff_test(
    name = "rules",
    bzl_library_target = "//ruby:defs",
)

stardoc_with_diff_test(
    name = "repository_rules",
    bzl_library_target = "//ruby:deps",
)

stardoc_with_diff_test(
    name = "rails",
    bzl_library_target = "//rails:rails_test_factory",
)

update_docs(name = "update")
