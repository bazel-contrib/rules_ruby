"""Unit tests for gemfile_lock_parser."""

load("@bazel_skylib//lib:unittest.bzl", "asserts", "unittest")
load(
    "//ruby/private/bundle_fetch:gemfile_lock_parser.bzl",
    _parse_gemfile_lock = "parse_gemfile_lock",
)

_GEMFILE_LOCK_WITH_GIT_GEM = """
GIT
  remote: https://github.com/example/my_gem.git
  revision: abc123def456789012345678901234567890abcd
  specs:
    my_gem (1.0.0)

GEM
  remote: https://rubygems.org/
  specs:
    rake (13.0.6)

PLATFORMS
  ruby

DEPENDENCIES
  my_gem!
  rake

BUNDLED WITH
   2.3.0
"""

_GEMFILE_LOCK_WITH_MULTI_GEM_GIT_REPO = """
GIT
  remote: https://github.com/example/monorepo.git
  revision: def456789012345678901234567890abcdef1234
  specs:
    gem_one (2.0.0)
    gem_two (2.1.0)

GEM
  remote: https://rubygems.org/
  specs:
    json (2.6.3)

PLATFORMS
  ruby

DEPENDENCIES
  gem_one!
  gem_two!
  json

BUNDLED WITH
   2.3.0
"""

_GEMFILE_LOCK_WITH_MULTIPLE_GIT_SOURCES = """
GIT
  remote: https://github.com/example/first_gem.git
  revision: 1111111111111111111111111111111111111111
  specs:
    first_gem (1.0.0)

GIT
  remote: https://github.com/example/second_gem.git
  revision: 2222222222222222222222222222222222222222
  specs:
    second_gem (2.0.0)

GEM
  remote: https://rubygems.org/
  specs:
    rake (13.0.6)

PLATFORMS
  ruby

DEPENDENCIES
  first_gem!
  second_gem!
  rake

BUNDLED WITH
   2.3.0
"""

_GEMFILE_LOCK_WITHOUT_GIT = """
GEM
  remote: https://rubygems.org/
  specs:
    rake (13.0.6)
    json (2.6.3)

PLATFORMS
  ruby

DEPENDENCIES
  rake
  json

BUNDLED WITH
   2.3.0
"""

def _parse_gemfile_lock_with_single_git_gem_test_impl(ctx):
    env = unittest.begin(ctx)

    result = _parse_gemfile_lock(
        _GEMFILE_LOCK_WITH_GIT_GEM,
        "https://rubygems.org/",
        {"2.3.0": "abc123"},
    )

    asserts.equals(env, 1, len(result.git_packages), "Expected 1 git package")

    git_pkg = result.git_packages[0]
    asserts.equals(
        env,
        "https://github.com/example/my_gem.git",
        git_pkg.remote,
        "Git remote URL mismatch",
    )
    asserts.equals(
        env,
        "abc123def456789012345678901234567890abcd",
        git_pkg.revision,
        "Git revision mismatch",
    )

    asserts.equals(env, 1, len(git_pkg.gems), "Expected 1 gem in git package")

    gem = git_pkg.gems[0]
    asserts.equals(env, "my_gem", gem.name, "Gem name mismatch")
    asserts.equals(env, "1.0.0", gem.version, "Gem version mismatch")
    asserts.equals(env, "my_gem-1.0.0", gem.full_name, "Gem full_name mismatch")
    asserts.equals(env, 1, len(result.remote_packages), "Expected 1 remote package")
    asserts.equals(env, "rake", result.remote_packages[0].name, "Remote package name mismatch")

    return unittest.end(env)

parse_gemfile_lock_with_single_git_gem_test = unittest.make(_parse_gemfile_lock_with_single_git_gem_test_impl)

def _parse_gemfile_lock_with_multi_gem_git_repo_test_impl(ctx):
    env = unittest.begin(ctx)

    result = _parse_gemfile_lock(
        _GEMFILE_LOCK_WITH_MULTI_GEM_GIT_REPO,
        "https://rubygems.org/",
        {"2.3.0": "abc123"},
    )

    asserts.equals(env, 1, len(result.git_packages), "Expected 1 git package")

    git_pkg = result.git_packages[0]
    asserts.equals(
        env,
        "https://github.com/example/monorepo.git",
        git_pkg.remote,
        "Git remote URL mismatch",
    )

    asserts.equals(env, 2, len(git_pkg.gems), "Expected 2 gems in git package")
    asserts.equals(env, "gem_one", git_pkg.gems[0].name, "First gem name mismatch")
    asserts.equals(env, "2.0.0", git_pkg.gems[0].version, "First gem version mismatch")
    asserts.equals(env, "gem_two", git_pkg.gems[1].name, "Second gem name mismatch")
    asserts.equals(env, "2.1.0", git_pkg.gems[1].version, "Second gem version mismatch")

    return unittest.end(env)

parse_gemfile_lock_with_multi_gem_git_repo_test = unittest.make(_parse_gemfile_lock_with_multi_gem_git_repo_test_impl)

def _parse_gemfile_lock_with_multiple_git_sources_test_impl(ctx):
    env = unittest.begin(ctx)

    result = _parse_gemfile_lock(
        _GEMFILE_LOCK_WITH_MULTIPLE_GIT_SOURCES,
        "https://rubygems.org/",
        {"2.3.0": "abc123"},
    )

    asserts.equals(env, 2, len(result.git_packages), "Expected 2 git packages")

    first_pkg = result.git_packages[0]
    asserts.equals(
        env,
        "https://github.com/example/first_gem.git",
        first_pkg.remote,
        "First git remote URL mismatch",
    )
    asserts.equals(
        env,
        "1111111111111111111111111111111111111111",
        first_pkg.revision,
        "First git revision mismatch",
    )
    asserts.equals(env, 1, len(first_pkg.gems), "Expected 1 gem in first git package")
    asserts.equals(env, "first_gem", first_pkg.gems[0].name, "First git gem name mismatch")

    second_pkg = result.git_packages[1]
    asserts.equals(
        env,
        "https://github.com/example/second_gem.git",
        second_pkg.remote,
        "Second git remote URL mismatch",
    )
    asserts.equals(
        env,
        "2222222222222222222222222222222222222222",
        second_pkg.revision,
        "Second git revision mismatch",
    )
    asserts.equals(env, 1, len(second_pkg.gems), "Expected 1 gem in second git package")
    asserts.equals(env, "second_gem", second_pkg.gems[0].name, "Second git gem name mismatch")

    return unittest.end(env)

parse_gemfile_lock_with_multiple_git_sources_test = unittest.make(_parse_gemfile_lock_with_multiple_git_sources_test_impl)

def _parse_gemfile_lock_without_git_test_impl(ctx):
    env = unittest.begin(ctx)

    result = _parse_gemfile_lock(
        _GEMFILE_LOCK_WITHOUT_GIT,
        "https://rubygems.org/",
        {"2.3.0": "abc123"},
    )

    asserts.equals(env, 0, len(result.git_packages), "Expected 0 git packages")
    asserts.equals(env, 2, len(result.remote_packages), "Expected 2 remote packages")

    return unittest.end(env)

parse_gemfile_lock_without_git_test = unittest.make(_parse_gemfile_lock_without_git_test_impl)

def _parse_gemfile_lock_git_gem_remote_is_git_url_test_impl(ctx):
    """Test that git gems have the git remote as their remote, not the rubygems remote."""
    env = unittest.begin(ctx)

    result = _parse_gemfile_lock(
        _GEMFILE_LOCK_WITH_GIT_GEM,
        "https://rubygems.org/",
        {"2.3.0": "abc123"},
    )

    git_pkg = result.git_packages[0]
    gem = git_pkg.gems[0]

    asserts.equals(
        env,
        "https://github.com/example/my_gem.git",
        gem.remote,
        "Git gem remote should be the git URL",
    )

    return unittest.end(env)

parse_gemfile_lock_git_gem_remote_is_git_url_test = unittest.make(_parse_gemfile_lock_git_gem_remote_is_git_url_test_impl)

def gemfile_lock_parser_test_suite():
    unittest.suite(
        "gemfile_lock_parser_tests",
        parse_gemfile_lock_with_single_git_gem_test,
        parse_gemfile_lock_with_multi_gem_git_repo_test,
        parse_gemfile_lock_with_multiple_git_sources_test,
        parse_gemfile_lock_without_git_test,
        parse_gemfile_lock_git_gem_remote_is_git_url_test,
    )
