"""Unit tests for utils."""

load("@bazel_skylib//lib:unittest.bzl", "asserts", "unittest")
load(
    "//ruby/private:utils.bzl",
    _normalize_bzlmod_repository_name = "normalize_bzlmod_repository_name",
    _resolve_bundle_build_env = "resolve_bundle_build_env",
    _to_rlocation_path = "to_rlocation_path",
)

def _normalize_bzlmod_repository_name_test_impl(ctx):
    env = unittest.begin(ctx)
    asserts.equals(env, _normalize_bzlmod_repository_name("bundle"), "bundle")
    asserts.equals(env, _normalize_bzlmod_repository_name("rules_ruby+override+ruby+bundle"), "bundle")
    asserts.equals(env, _normalize_bzlmod_repository_name("rules_ruby~override~ruby~bundle"), "bundle")
    return unittest.end(env)

def _to_rlocation_path_test_impl(ctx):
    env = unittest.begin(ctx)

    # External workspace file
    asserts.equals(
        env,
        _to_rlocation_path(None, struct(short_path = "../other_ws/file.rb")),
        "other_ws/file.rb",
    )

    # Main workspace file, no owner.workspace_name
    asserts.equals(
        env,
        _to_rlocation_path(
            struct(workspace_name = "my_ws"),
            struct(short_path = "file.rb", owner = struct(workspace_name = "")),
        ),
        "my_ws/file.rb",
    )

    # File with owner.workspace_name
    asserts.equals(
        env,
        _to_rlocation_path(
            None,
            struct(short_path = "lib/file.rb", owner = struct(workspace_name = "other_ws")),
        ),
        "other_ws/lib/file.rb",
    )

    # No workspace name at all (fallback)
    asserts.equals(
        env,
        _to_rlocation_path(
            struct(workspace_name = ""),
            struct(short_path = "file.rb", owner = struct(workspace_name = "")),
        ),
        "file.rb",
    )

    return unittest.end(env)

def _resolve_bundle_build_env_test_impl(ctx):
    env = unittest.begin(ctx)
    rel = {
        "BUNDLE_BUILD__PSYCH": "--with-libyaml-dir=dist",
        "BUNDLE_BUILD__OPENSSL": "--with-openssl-dir=dist",
    }

    # Default layout: external repositories live under external/.
    asserts.equals(
        env,
        {
            "BUNDLE_BUILD__PSYCH": '"--with-libyaml-dir=$PWD/external/rules_ruby++ruby+ruby/dist"',
            "BUNDLE_BUILD__OPENSSL": '"--with-openssl-dir=$PWD/external/rules_ruby++ruby+ruby/dist"',
        },
        _resolve_bundle_build_env("external/rules_ruby++ruby+ruby/dist/bin/ruby", rel),
    )

    # --experimental_sibling_repository_layout
    asserts.equals(
        env,
        {"BUNDLE_BUILD__PSYCH": '"--with-libyaml-dir=$PWD/../ruby/dist"'},
        _resolve_bundle_build_env("../ruby/dist/bin/ruby", {"BUNDLE_BUILD__PSYCH": "--with-libyaml-dir=dist"}),
    )

    # Toolchain in the main repository.
    asserts.equals(
        env,
        {"BUNDLE_BUILD__PSYCH": '"--with-libyaml-dir=$PWD/dist"'},
        _resolve_bundle_build_env("dist/bin/ruby", {"BUNDLE_BUILD__PSYCH": "--with-libyaml-dir=dist"}),
    )

    # Toolchains without the field set nothing.
    asserts.equals(env, {}, _resolve_bundle_build_env("external/ruby/dist/bin/ruby", {}))

    return unittest.end(env)

normalize_bzlmod_repository_name_test = unittest.make(_normalize_bzlmod_repository_name_test_impl)
to_rlocation_path_test = unittest.make(_to_rlocation_path_test_impl)
resolve_bundle_build_env_test = unittest.make(_resolve_bundle_build_env_test_impl)

def utils_test_suite():
    unittest.suite(
        "utils_tests",
        normalize_bzlmod_repository_name_test,
        to_rlocation_path_test,
        resolve_bundle_build_env_test,
    )
