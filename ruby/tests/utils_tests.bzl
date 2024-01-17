"""Unit tests for utils."""

load("@bazel_skylib//lib:unittest.bzl", "asserts", "unittest")
load(
    "//ruby/private:utils.bzl",
    _normalize_bzlmod_repository_name = "normalize_bzlmod_repository_name",
)

def _normalize_bzlmod_repository_name_test_impl(ctx):
    env = unittest.begin(ctx)
    asserts.equals(env, _normalize_bzlmod_repository_name("bundle"), "bundle")
    asserts.equals(env, _normalize_bzlmod_repository_name("rules_ruby~override~ruby~bundle"), "bundle")
    return unittest.end(env)

normalize_bzlmod_repository_name_test = unittest.make(_normalize_bzlmod_repository_name_test_impl)

def utils_test_suite():
    unittest.suite("utils_tests", normalize_bzlmod_repository_name_test)
