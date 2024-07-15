"Implementation details for rb_bundle_fetch"

load("@bazel_skylib//lib:versions.bzl", "versions")
load("//ruby/private:bundler_checksums.bzl", "BUNDLER_CHECKSUMS")
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
    ruby = {ruby},
)
"""

_GEM_BINARY_BUILD_FRAGMENT = """
rb_binary(
    name = "{name}",
    main = "{path}/{name}",
    deps = ["//:{repository_name}"],
    ruby = {ruby},
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

def _download_gem(repository_ctx, gem, cache_path, sha256 = None):
    """Downloads gem into a predefined vendor/cache location.

    Returns sha256 hash of the downloaded gem.
    """
    url = "{remote}gems/{filename}".format(remote = gem.remote, filename = gem.filename)

    # Bazel doesn't accept `None` for sha256 so we have to omit the kwarg if
    # we don't have sha256.
    kwargs = {}
    if sha256:
        kwargs["sha256"] = sha256
    download = repository_ctx.download(url = url, output = "%s/%s" % (cache_path, gem.filename), **kwargs)
    return download.sha256

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

    # We insert our default value here, not on the attribute's default, so it
    # isn't documented. # The BUNDLER_CHECKSUMS value is huge and not useful to
    # document.
    bundler_checksums = BUNDLER_CHECKSUMS
    if len(repository_ctx.attr.bundler_checksums) > 0:
        bundler_checksums = repository_ctx.attr.bundler_checksums

    gemfile_lock = parse_gemfile_lock(
        repository_ctx.read(gemfile_lock_path),
        repository_ctx.attr.bundler_remote,
        bundler_checksums,
    )
    if not versions.is_at_least("2.2.19", gemfile_lock.bundler.version):
        fail(_OUTDATED_BUNDLER_ERROR)

    if len(gemfile_lock.git_packages) > 0:
        fail(_GIT_UNSUPPORTED_ERROR)

    executables = []
    gem_full_names = []
    gem_fragments = []
    gem_install_fragments = []
    gem_checksums = {}
    ruby_toolchain_attr = "None" if repository_ctx.attr.ruby == None else '"{}"'.format(repository_ctx.attr.ruby)
    repository_name = _normalize_bzlmod_repository_name(repository_ctx.name)

    # Fetch gems and expose them as `rb_gem()` targets.
    for gem in gemfile_lock.remote_packages:
        gem_checksums[gem.full_name] = _download_gem(
            repository_ctx,
            gem,
            cache_path,
            repository_ctx.attr.gem_checksums.get(gem.full_name, None),
        )
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
    _download_gem(repository_ctx, gemfile_lock.bundler, cache_path, gemfile_lock.bundler.sha256)
    gem_full_names.append(":%s" % gemfile_lock.bundler.full_name)
    gem_install_fragments.append(
        _GEM_INSTALL_BUILD_FRAGMENT.format(
            name = gemfile_lock.bundler.full_name,
            gem = gemfile_lock.bundler.filename,
            cache_path = cache_path,
            ruby = ruby_toolchain_attr,
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
                ruby = ruby_toolchain_attr,
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
            "{ruby}": ruby_toolchain_attr,
        },
    )

    if len(repository_ctx.attr.gem_checksums) != len(gem_checksums):
        return {
            "name": repository_ctx.name,
            "gemfile": repository_ctx.attr.gemfile,
            "gemfile_lock": repository_ctx.attr.gemfile_lock,
            "srcs": repository_ctx.attr.srcs,
            "env": repository_ctx.attr.env,
            "bundler_remote": repository_ctx.attr.bundler_remote,
            "bundler_checksums": repository_ctx.attr.bundler_checksums,
            "gem_checksums": gem_checksums,
        }
    return None

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
        "bundler_checksums": attr.string_dict(
            doc = "Custom map from Bundler version to its SHA-256 checksum.",
        ),
        "gem_checksums": attr.string_dict(
            default = {},
            doc = "SHA-256 checksums for remote gems. Keys are gem names (e.g. foobar-1.2.3), values are SHA-256 checksums.",
        ),
        "ruby": attr.label(
            doc = "Override Ruby toolchain to use for installation.",
            providers = [platform_common.ToolchainInfo],
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

Checksums for gems in Gemfile.lock are printed by the ruleset during the build.
It's recommended to add them to `gem_checksums` attribute.

`WORKSPACE`:
```bazel
rb_bundle_fetch(
    name = "bundle",
    gemfile = "//:Gemfile",
    gemfile_lock = "//:Gemfile.lock",
    gem_checksums = {
        "ast-2.4.2": "1e280232e6a33754cde542bc5ef85520b74db2aac73ec14acef453784447cc12",
        "concurrent-ruby-1.2.2": "3879119b8b75e3b62616acc256c64a134d0b0a7a9a3fcba5a233025bcde22c4f",
    },
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
