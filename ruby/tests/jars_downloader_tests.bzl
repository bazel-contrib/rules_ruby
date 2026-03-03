"""Unit tests for jars_downloader."""

load("@bazel_skylib//lib:unittest.bzl", "asserts", "unittest")
load(
    "//ruby/private/bundle_fetch:jars_downloader.bzl",
    "jars_downloader_internal",
)

def _is_java_gem_test_impl(ctx):
    env = unittest.begin(ctx)
    asserts.true(env, jars_downloader_internal.is_java_gem(struct(version = "5.0.1-java")))
    asserts.true(env, jars_downloader_internal.is_java_gem(struct(version = "5.0.1-java-8")))
    asserts.false(env, jars_downloader_internal.is_java_gem(struct(version = "5.0.1")))
    return unittest.end(env)

def _parse_jar_requirement_test_impl(ctx):
    env = unittest.begin(ctx)
    res = jars_downloader_internal.parse_jar_requirement("jar org.yaml:snakeyaml, 1.33")
    asserts.equals(env, "org.yaml", res.group_id)
    asserts.equals(env, "snakeyaml", res.artifact_id)
    asserts.equals(env, "1.33", res.version)

    asserts.equals(env, None, jars_downloader_internal.parse_jar_requirement("not a jar"))
    return unittest.end(env)

def _fetch_gem_requirements_null_test_impl(ctx):
    env = unittest.begin(ctx)

    # Mock repository_ctx
    mock_ctx = struct(
        download = lambda **kwargs: struct(success = True),
        read = lambda file: '{"requirements": null}',
        delete = lambda file: None,
    )

    gem = struct(name = "test-gem", version = "1.0.0-java")
    res = jars_downloader_internal.fetch_gem_requirements(mock_ctx, gem)
    asserts.equals(env, [], res)

    return unittest.end(env)

is_java_gem_test = unittest.make(_is_java_gem_test_impl)
parse_jar_requirement_test = unittest.make(_parse_jar_requirement_test_impl)
fetch_gem_requirements_null_test = unittest.make(_fetch_gem_requirements_null_test_impl)

def jars_downloader_test_suite():
    unittest.suite(
        "jars_downloader_tests",
        is_java_gem_test,
        parse_jar_requirement_test,
        fetch_gem_requirements_null_test,
    )
