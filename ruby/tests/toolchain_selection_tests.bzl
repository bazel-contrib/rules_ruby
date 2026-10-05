"""Regression tests for default Ruby toolchain selection."""

load("@bazel_skylib//lib:unittest.bzl", "asserts", "unittest")
load("//ruby/private/toolchain:selection.bzl", "select_toolchains")

def _toolchain(version = "4.0.7", name = "ruby", **kwargs):
    attrs = dict(
        name = name,
        version = version,
        version_file = None,
        msys2_packages = ["libyaml"],
        ruby_build_version = "20260924",
        portable_ruby = True,
        portable_ruby_release_suffix = "",
        portable_ruby_checksums = {},
    )
    attrs.update(kwargs)
    return struct(**attrs)

def _module(name, *toolchains, **kwargs):
    return struct(name = name, is_root = kwargs.get("is_root", False), tags = struct(toolchain = toolchains))

def _selection_test_impl(ctx):
    env = unittest.begin(ctx)
    fallback = _module("rules_ruby", _toolchain())
    custom = _module("app", _toolchain("jruby-10.1.2.0"), is_root = True)
    dependency = _module("dependency", _toolchain("3.4.11"))

    asserts.equals(env, "4.0.7", select_toolchains([fallback])["ruby"]["version"])
    asserts.equals(env, "jruby-10.1.2.0", select_toolchains([custom, fallback, dependency])["ruby"]["version"])

    # A dependency's explicit version wins over the built-in fallback in either order.
    for modules in [[fallback, dependency], [dependency, fallback]]:
        asserts.equals(env, "3.4.11", select_toolchains(modules)["ruby"]["version"])

    # Matching declarations from different dependencies are accepted.
    matching = _module("matching", _toolchain("3.4.11"))
    asserts.equals(env, "3.4.11", select_toolchains([dependency, matching, fallback])["ruby"]["version"])

    # Root settings override the complete configuration, including version files
    # and the choice to compile from source, rather than just the version string.
    custom = _module("app", _toolchain("", version_file = Label("//:.ruby-version"), portable_ruby = False), is_root = True)
    config = select_toolchains([custom, fallback])["ruby"]
    asserts.equals(env, Label("//:.ruby-version"), config["version_file"])
    asserts.false(env, config["portable_ruby"])

    # A differently named root toolchain leaves the fallback available.
    custom = _module("app", _toolchain("3.4.11", name = "other_ruby"), is_root = True)
    configs = select_toolchains([custom, fallback])
    asserts.equals(env, "3.4.11", configs["other_ruby"]["version"])
    asserts.equals(env, "4.0.7", configs["ruby"]["version"])
    return unittest.end(env)

selection_test = unittest.make(_selection_test_impl)

def toolchain_selection_test_suite():
    unittest.suite("toolchain_selection_tests", selection_test)
