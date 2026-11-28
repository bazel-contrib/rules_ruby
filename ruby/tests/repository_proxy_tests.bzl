"""Unit tests for the toolchain proxy repository."""

load("@bazel_skylib//lib:unittest.bzl", "asserts", "unittest")
load("//ruby/private/toolchain:repository_proxy.bzl", "proxy_build_content")

def _platform_aliases_test_impl(ctx):
    env = unittest.begin(ctx)
    content = proxy_build_content(
        ["ruby_x86_64_linux|x86_64_linux", "ruby_arm64_darwin|arm64_darwin"],
        "@rules_ruby//ruby:toolchain_type",
    )
    asserts.equals(env, 2, content.count("toolchain("))
    for plat in ["x86_64_linux", "arm64_darwin"]:
        asserts.true(env, """alias(
    name = "{plat}",
    actual = "@ruby_{plat}//:toolchain",
""".format(plat = plat) in content, "no alias for " + plat)
    return unittest.end(env)

def _default_alias_test_impl(ctx):
    env = unittest.begin(ctx)
    content = proxy_build_content(["ruby|"], "@rules_ruby//ruby:toolchain_type")
    asserts.true(env, 'name = "toolchain_default"' in content)
    asserts.true(env, """alias(
    name = "default",
    actual = "@ruby//:toolchain",
""" in content)
    return unittest.end(env)

platform_aliases_test = unittest.make(_platform_aliases_test_impl)
default_alias_test = unittest.make(_default_alias_test_impl)

def repository_proxy_test_suite():
    unittest.suite(
        "repository_proxy_tests",
        platform_aliases_test,
        default_alias_test,
    )
