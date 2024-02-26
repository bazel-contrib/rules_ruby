"Implementation details for rb_bundle_fetch"

load("@bazel_skylib//lib:versions.bzl", "versions")
load(
    "//ruby/private:utils.bzl",
    _join_and_indent = "join_and_indent",
    _normalize_bzlmod_repository_name = "normalize_bzlmod_repository_name",
)
load("//ruby/private/bundle_fetch:gemfile_lock_parser.bzl", "parse_gemfile_lock")

# Location of Bundler binstubs to generate shims and use during rb_bundle_install(...).
BINSTUBS_LOCATION = "bin/private"

_GEM_BUILD_FRAGMENT = """
rb_gem(
    name = "{name}",
    gem = "{cache_path}/{gem}",
)
"""

_GEM_INSTALL_BUILD_FRAGMENT = """
rb_gem_install(
    name = "{name}",
    gem = "{cache_path}/{gem}",
)
"""

_GEM_BINARY_BUILD_FRAGMENT = """
rb_binary(
    name = "{name}",
    main = "{path}/{name}",
    deps = ["//:{repository_name}"],
)
"""

_GIT_UNSUPPORTED_ERROR = """

rb_bundle_fetch(...) does not support gems installed from Git yet.
See https://github.com/bazel-contrib/rules_ruby/issues/62 for more details.

"""

_OUTDATED_BUNDLER_ERROR = """

rb_bundle_fetch(...) requires Bundler 2.2.19 or later in Gemfile.lock.
Please update Bundler version and try again.
See https://github.com/rubygems/rubygems/issues/4620 for more details.

"""

def _download_gem(repository_ctx, gem, cache_path):
    """Downloads gem into a predefined vendor/cache location."""
    url = "{remote}gems/{filename}".format(remote = gem.remote, filename = gem.filename)
    repository_ctx.download(url = url, output = "%s/%s" % (cache_path, gem.filename))

def _get_gem_executables(repository_ctx, gem, cache_path):
    """Unpacks downloaded gem and returns its executables.

    Ideally, we would read the list of executables from gem metadata.gz,
    which is a compressed YAML file. It has a separate `executables` field
    containing the exact list of files. However, Bazel cannot decompress `.gz`
    files, so we would need to use an external tool such as `gzcat` or `busybox`.
    The tool should also work on all OSes. For now, a simpler path is taken
    where we unpack the gem completely and then try to determin executables
    by looking into its `bin` and `exe` locations. This is accurate enough so far,
    so some exotic gems might not work correctly.
    """
    executables = []
    repository_ctx.symlink(cache_path + "/" + gem.filename, gem.filename + ".tar")
    repository_ctx.extract(gem.filename + ".tar", output = gem.full_name)
    data = "/".join([gem.full_name, "data"])
    repository_ctx.extract("/".join([gem.full_name, "data.tar.gz"]), output = data)
    gem_contents = repository_ctx.path(data)

    executable_dirnames = ["bin", "exe"]
    for executable_dirname in executable_dirnames:
        if gem_contents.get_child(executable_dirname).exists:
            for executable in gem_contents.get_child(executable_dirname).readdir():
                executables.append(executable.basename)

    _cleanup_downloads(repository_ctx, gem)
    return executables

def _cleanup_downloads(repository_ctx, gem):
    """Removes unnecessary downloaded/unpacked files."""
    repository_ctx.delete(gem.full_name)
    repository_ctx.delete(gem.filename + ".tar")

def _rb_bundle_fetch_impl(repository_ctx):
    # Define vendor/cache relative to the location of Gemfile.
    # This is expected by Bundler to operate correctly.
    gemfile_dir = repository_ctx.attr.gemfile.name.rpartition("/")[0]
    cache_path = ("%s/vendor/cache" % gemfile_dir).removeprefix("/")

    # Copy all necessary inputs to the repository.
    gemfile_path = repository_ctx.path(repository_ctx.attr.gemfile)
    gemfile_lock_path = repository_ctx.path(repository_ctx.attr.gemfile_lock)
    repository_ctx.file(repository_ctx.attr.gemfile.name, repository_ctx.read(gemfile_path))
    repository_ctx.file(repository_ctx.attr.gemfile_lock.name, repository_ctx.read(gemfile_lock_path))
    srcs = []
    for src in repository_ctx.attr.srcs:
        srcs.append(src.name)
        repository_ctx.file(src.name, repository_ctx.read(src))

    gemfile_lock = parse_gemfile_lock(
        repository_ctx.read(gemfile_lock_path),
        repository_ctx.attr.bundler_remote,
    )
    if not versions.is_at_least("2.2.19", gemfile_lock.bundler.version):
        fail(_OUTDATED_BUNDLER_ERROR)

    if len(gemfile_lock.git_packages) > 0:
        fail(_GIT_UNSUPPORTED_ERROR)

    executables = []
    gem_full_names = []
    gem_fragments = []
    gem_install_fragments = []
    repository_name = _normalize_bzlmod_repository_name(repository_ctx.name)

    # Fetch gems and expose them as `rb_gem()` targets.
    for gem in gemfile_lock.remote_packages:
        _download_gem(repository_ctx, gem, cache_path)
        executables.extend(_get_gem_executables(repository_ctx, gem, cache_path))
        gem_full_names.append(":%s" % gem.full_name)
        gem_fragments.append(
            _GEM_BUILD_FRAGMENT.format(
                name = gem.full_name,
                gem = gem.filename,
                cache_path = cache_path,
            ),
        )

    # Fetch Bundler and define an `rb_gem_install()` target for it.
    _download_gem(repository_ctx, gemfile_lock.bundler, cache_path)
    gem_full_names.append(":%s" % gemfile_lock.bundler.full_name)
    gem_install_fragments.append(
        _GEM_INSTALL_BUILD_FRAGMENT.format(
            name = gemfile_lock.bundler.full_name,
            gem = gemfile_lock.bundler.filename,
            cache_path = cache_path,
        ),
    )

    # Create `bin` package with shims for gem executables.
    # This allows targets to depend on `@bundle//bin:rake`
    # and also run those directly such as `bazel run @bundle//bin:rake`.
    gem_binaries_fragments = []
    for executable in depset(executables).to_list():
        repository_ctx.file("%s/%s" % (BINSTUBS_LOCATION, executable))
        gem_binaries_fragments.append(
            _GEM_BINARY_BUILD_FRAGMENT.format(
                name = executable,
                repository_name = repository_name,
                path = BINSTUBS_LOCATION.partition("/")[-1],
            ),
        )
    repository_ctx.template(
        "bin/BUILD",
        repository_ctx.attr._bin_build_tpl,
        executable = False,
        substitutions = {
            "{name}": repository_name,
            "{gem_binary_fragments}": "".join(gem_binaries_fragments),
        },
    )

    repository_ctx.template(
        "BUILD",
        repository_ctx.attr._build_tpl,
        executable = False,
        substitutions = {
            "{name}": repository_name,
            "{srcs}": _join_and_indent(srcs),
            "{gemfile_path}": repository_ctx.attr.gemfile.name,
            "{gemfile_lock_path}": repository_ctx.attr.gemfile_lock.name,
            "{gems}": _join_and_indent(gem_full_names),
            "{gem_fragments}": "".join(gem_fragments),
            "{gem_install_fragments}": "".join(gem_install_fragments),
            "{env}": repr(repository_ctx.attr.env),
        },
    )

rb_bundle_fetch = repository_rule(
    implementation = _rb_bundle_fetch_impl,
    attrs = {
        "gemfile": attr.label(
            allow_single_file = ["Gemfile"],
            mandatory = True,
            doc = "Gemfile to install dependencies from.",
        ),
        "gemfile_lock": attr.label(
            allow_single_file = ["Gemfile.lock"],
            mandatory = True,
            doc = "Gemfile.lock to install dependencies from.",
        ),
        "srcs": attr.label_list(
            allow_files = True,
            doc = "List of Ruby source files necessary during installation.",
        ),
        "env": attr.string_dict(
            doc = "Environment variables to use during installation.",
        ),
        "bundler_remote": attr.string(
            default = "https://rubygems.org/",
            doc = "Remote to fetch the bundler gem from.",
        ),
        "_build_tpl": attr.label(
            allow_single_file = True,
            default = "@rules_ruby//:ruby/private/bundle_fetch/BUILD.tpl",
        ),
        "_bin_build_tpl": attr.label(
            allow_single_file = True,
            default = "@rules_ruby//:ruby/private/bundle_fetch/bin/BUILD.tpl",
        ),
    },
    doc = """
Fetches Bundler dependencies to be automatically installed by other targets.

Currently doesn't support installing gems from Git repositories,
see https://github.com/bazel-contrib/rules_ruby/issues/62.

`WORKSPACE`:
```bazel
load("@rules_ruby//ruby:deps.bzl", "rb_bundle_fetch")

rb_bundle_fetch(
    name = "bundle",
    gemfile = "//:Gemfile",
    gemfile_lock = "//:Gemfile.lock",
    srcs = [
        "//:gem.gemspec",
        "//:lib/gem/version.rb",
    ]
)
```

All the installed gems can be accessed using `@bundle` target and additionally
gems binary files can also be used via BUILD rules or directly with `bazel run`:

`BUILD`:
```bazel
load("@rules_ruby//ruby:defs.bzl", "rb_test")

package(default_visibility = ["//:__subpackages__"])

rb_test(
    name = "rubocop",
    main = "@bundle//bin:rubocop",
    deps = ["@bundle"],
)
```
    """,
)
