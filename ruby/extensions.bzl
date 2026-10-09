"Module extensions used by bzlmod"

load("@bazel_features//:features.bzl", "bazel_features")
load("//ruby/private:download.bzl", "RUBY_BUILD_VERSION")
load("//ruby/private/toolchain:selection.bzl", "select_toolchains")
load(":deps.bzl", "rb_bundle_fetch", "rb_register_toolchains")

def _resolve_version(module_ctx, toolchain):
    """Resolve the Ruby version string from `version` or `version_file`.

    `rb_register_toolchains` needs to know whether the requested engine is
    JRuby to decide between the multi-platform `portable_ruby` path and the
    single-platform path. When the user supplies `version_file` instead of an
    explicit `version`, the extension reads the file here so the decision can
    be made at extension-evaluation time, before the repo rules fire.
    """
    if toolchain.version:
        return toolchain.version
    if not toolchain.version_file:
        return None
    content = module_ctx.read(toolchain.version_file).strip("\r\n")
    if toolchain.version_file.name == ".tool-versions":
        for line in content.splitlines():
            if line.startswith("ruby"):
                return line.partition(" ")[-1]
        return None
    return content

ruby_bundle_fetch = tag_class(attrs = {
    "name": attr.string(doc = "Resulting repository name for the bundle"),
    "srcs": attr.label_list(),
    "env": attr.string_dict(),
    "extra_args": attr.string_list(doc = "Extra arguments appended to `bundle install`. Supports `$(location ...)` against `data`."),
    "data": attr.label_list(doc = "Files referenced from `extra_args` via `$(location ...)`."),
    "binstubs": attr.bool(default = True, doc = "Run `bundle binstubs --all` after install. Set False for cross-platform bundles."),
    "gemfile": attr.label(),
    "gemfile_lock": attr.label(),
    "gem_checksums": attr.string_dict(),
    "jar_checksums": attr.string_dict(),
    "bundler_remote": attr.string(default = "https://rubygems.org/"),
    "bundler_checksums": attr.string_dict(),
})

ruby_toolchain = tag_class(attrs = {
    "name": attr.string(doc = "Base name for generated repositories, allowing multiple to be registered."),
    "version": attr.string(doc = "Explicit version of ruby."),
    "version_file": attr.label(doc = "File to read Ruby version from."),
    "ruby_build_version": attr.string(doc = "Version of ruby-build to use.", default = RUBY_BUILD_VERSION),
    "msys2_packages": attr.string_list(doc = "Extra MSYS2 packages to install.", default = ["libyaml"]),
    "portable_ruby": attr.bool(
        doc = """\
When True, downloads portable Ruby from bazel-contrib/portable-ruby instead of compiling via \
ruby-build. Has no effect on JRuby, TruffleRuby, or Windows.\
""",
        default = False,
    ),
    "portable_ruby_release_suffix": attr.string(
        doc = """\
Release suffix for portable Ruby downloads. When empty (default), uses the built-in \
PORTABLE_RUBY_DEFAULT_SUFFIXES mapping. Set explicitly to pin to a specific rebuild, \
e.g. "2" downloads version X.Y.Z-2.\
""",
        default = "",
    ),
    "portable_ruby_checksums": attr.string_dict(
        doc = """\
Platform checksums for portable Ruby downloads, overriding built-in checksums. \
Keys: linux-x86_64, linux-arm64, macos-arm64, macos-x86_64.\
""",
        default = {},
    ),
})

def _ruby_module_extension(module_ctx):
    direct_dep_names = []
    direct_dev_dep_names = []
    registrations = select_toolchains(module_ctx.modules)
    for mod in module_ctx.modules:
        for bundle_fetch in mod.tags.bundle_fetch:
            rb_bundle_fetch(
                name = bundle_fetch.name,
                srcs = bundle_fetch.srcs,
                env = bundle_fetch.env,
                extra_args = bundle_fetch.extra_args,
                data = [str(label) for label in bundle_fetch.data],
                binstubs = bundle_fetch.binstubs,
                gemfile = bundle_fetch.gemfile,
                gemfile_lock = bundle_fetch.gemfile_lock,
                gem_checksums = bundle_fetch.gem_checksums,
                jar_checksums = bundle_fetch.jar_checksums,
                bundler_remote = bundle_fetch.bundler_remote,
                bundler_checksums = bundle_fetch.bundler_checksums,
            )
            if not mod.is_root:
                continue
            if module_ctx.is_dev_dependency(bundle_fetch):
                direct_dev_dep_names.append(bundle_fetch.name)
            else:
                direct_dep_names.append(bundle_fetch.name)

        if mod.is_root:
            for toolchain in mod.tags.toolchain:
                names = [toolchain.name, "%s_toolchains" % toolchain.name]
                if module_ctx.is_dev_dependency(toolchain):
                    direct_dev_dep_names.extend(names)
                else:
                    direct_dep_names.extend(names)

    for name, config in registrations.items():
        rb_register_toolchains(
            name = name,
            resolved_version = _resolve_version(module_ctx, struct(**config)),
            **config
        )

    direct_dep_names = {name: None for name in direct_dep_names}.keys()
    direct_dev_dep_names = {name: None for name in direct_dev_dep_names if name not in direct_dep_names}.keys()

    if bazel_features.external_deps.extension_metadata_has_reproducible:
        return module_ctx.extension_metadata(
            reproducible = True,
            root_module_direct_deps = direct_dep_names,
            root_module_direct_dev_deps = direct_dev_dep_names,
        )
    else:
        return module_ctx.extension_metadata(
            root_module_direct_deps = direct_dep_names,
            root_module_direct_dev_deps = direct_dev_dep_names,
        )

ruby = module_extension(
    implementation = _ruby_module_extension,
    tag_classes = {
        "bundle_fetch": ruby_bundle_fetch,
        "toolchain": ruby_toolchain,
    },
)
