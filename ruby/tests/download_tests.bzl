"""Unit tests for the portable Ruby download helpers."""

load("@bazel_skylib//lib:unittest.bzl", "asserts", "unittest")
load(
    "//ruby/private:download.bzl",
    _is_reproducible = "is_reproducible",
    _portable_ruby_bundle_build_env = "portable_ruby_bundle_build_env",
)

def _portable_ruby_bundle_build_env_test_impl(ctx):
    env = unittest.begin(ctx)

    # The psych/openssl options are kept, with repository-relative paths.
    asserts.equals(
        env,
        {
            "BUNDLE_BUILD__PSYCH": "--with-libyaml-dir=dist",
            "BUNDLE_BUILD__OPENSSL": "--with-openssl-dir=dist",
        },
        _portable_ruby_bundle_build_env(has_libyaml = True, has_openssl = True),
    )
    asserts.equals(
        env,
        {"BUNDLE_BUILD__PSYCH": "--with-libyaml-dir=dist"},
        _portable_ruby_bundle_build_env(has_libyaml = True, has_openssl = False),
    )
    asserts.equals(
        env,
        {"BUNDLE_BUILD__OPENSSL": "--with-openssl-dir=dist"},
        _portable_ruby_bundle_build_env(has_libyaml = False, has_openssl = True),
    )
    asserts.equals(
        env,
        {},
        _portable_ruby_bundle_build_env(has_libyaml = False, has_openssl = False),
    )

    # No value may be an absolute path.
    for value in _portable_ruby_bundle_build_env(has_libyaml = True, has_openssl = True).values():
        asserts.false(env, value.partition("=")[2].startswith("/"), "absolute path in %s" % value)

    return unittest.end(env)

def _is_reproducible_test_impl(ctx):
    env = unittest.begin(ctx)

    pinned = {"platform": "x86_64_linux", "sha256": "0" * 64}
    asserts.true(env, _is_reproducible("3.4.8", portable_ruby = True, is_windows_target = False, **pinned))
    asserts.false(env, _is_reproducible("3.4.8", portable_ruby = False, is_windows_target = False, **pinned))
    asserts.false(env, _is_reproducible("3.4.8", portable_ruby = True, is_windows_target = True, **pinned))
    asserts.false(env, _is_reproducible("system", portable_ruby = True, is_windows_target = False, **pinned))
    asserts.false(env, _is_reproducible("jruby-10.0.2.0", portable_ruby = True, is_windows_target = False, **pinned))
    asserts.false(env, _is_reproducible("truffleruby-25.0.0", portable_ruby = True, is_windows_target = False, **pinned))

    # Host-detected platform or an unpinned download is not reproducible.
    asserts.false(env, _is_reproducible("3.4.8", portable_ruby = True, is_windows_target = False, platform = "", sha256 = "0" * 64))
    asserts.false(env, _is_reproducible("3.4.8", portable_ruby = True, is_windows_target = False, platform = "x86_64_linux", sha256 = None))

    return unittest.end(env)

portable_ruby_bundle_build_env_test = unittest.make(_portable_ruby_bundle_build_env_test_impl)
is_reproducible_test = unittest.make(_is_reproducible_test_impl)

def download_test_suite():
    unittest.suite(
        "download_tests",
        portable_ruby_bundle_build_env_test,
        is_reproducible_test,
    )
