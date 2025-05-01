"Module extensions used by bzlmod"

load("@bazel_features//:features.bzl", "bazel_features")
load("//ruby/private:download.bzl", "RUBY_BUILD_VERSION")
load("//ruby/private:toolchain.bzl", "DEFAULT_RUBY_REPOSITORY")
load(":deps.bzl", "rb_bundle", "rb_bundle_fetch", "rb_register_toolchains")

ruby_bundle = tag_class(attrs = {
    "name": attr.string(doc = "Resulting repository name for the bundle"),
    "srcs": attr.label_list(),
    "env": attr.string_dict(),
    "gemfile": attr.label(),
    "toolchain": attr.label(),
})

ruby_bundle_fetch = tag_class(attrs = {
    "name": attr.string(doc = "Resulting repository name for the bundle"),
    "srcs": attr.label_list(),
    "env": attr.string_dict(),
    "gemfile": attr.label(),
    "gemfile_lock": attr.label(),
    "gem_checksums": attr.string_dict(),
    "bundler_remote": attr.string(default = "https://rubygems.org/"),
    "bundler_checksums": attr.string_dict(),
})

ruby_toolchain = tag_class(attrs = {
    "name": attr.string(doc = "Base name for generated repositories, allowing multiple to be registered."),
    "version": attr.string(doc = "Explicit version of ruby."),
    "version_file": attr.label(doc = "File to read Ruby version from."),
    "ruby_build_version": attr.string(doc = "Version of ruby-build to use.", default = RUBY_BUILD_VERSION),
    "msys2_packages": attr.string_list(doc = "Extra MSYS2 packages to install.", default = ["libyaml"]),
})

def _ruby_module_extension(module_ctx):
    direct_dep_names = []
    direct_dev_dep_names = []
    registrations = {}
    for mod in module_ctx.modules:
        for bundle in mod.tags.bundle:
            rb_bundle(
                name = bundle.name,
                srcs = bundle.srcs,
                env = bundle.env,
                gemfile = bundle.gemfile,
                toolchain = bundle.toolchain,
            )
            if module_ctx.is_dev_dependency(bundle):
                direct_dev_dep_names.append(bundle.name)
            else:
                direct_dep_names.append(bundle.name)

        for bundle_fetch in mod.tags.bundle_fetch:
            rb_bundle_fetch(
                name = bundle_fetch.name,
                srcs = bundle_fetch.srcs,
                env = bundle_fetch.env,
                gemfile = bundle_fetch.gemfile,
                gemfile_lock = bundle_fetch.gemfile_lock,
                gem_checksums = bundle_fetch.gem_checksums,
                bundler_remote = bundle_fetch.bundler_remote,
                bundler_checksums = bundle_fetch.bundler_checksums,
            )
            if module_ctx.is_dev_dependency(bundle_fetch):
                direct_dev_dep_names.append(bundle_fetch.name)
            else:
                direct_dep_names.append(bundle_fetch.name)

        for toolchain in mod.tags.toolchain:
            # Prevent a users dependencies creating conflicting toolchain names
            if toolchain.name != DEFAULT_RUBY_REPOSITORY and not mod.is_root:
                fail("Only the root module may provide a name for the ruby toolchain.")

            if toolchain.name in registrations.keys():
                if toolchain.version == registrations[toolchain.name]:
                    # No problem to register a matching toolchain twice
                    continue
                fail("Multiple conflicting toolchains declared for name {} ({}, {}) and {}".format(
                    toolchain.name,
                    toolchain.version,
                    toolchain.version_file,
                    toolchain.ruby_build_version,
                    registrations[toolchain.name],
                ))
            else:
                registrations[toolchain.name] = (
                    toolchain.version,
                    toolchain.version_file,
                    toolchain.msys2_packages,
                    toolchain.ruby_build_version,
                )
                if module_ctx.is_dev_dependency(toolchain):
                    direct_dev_dep_names.append(toolchain.name)
                    direct_dev_dep_names.append("%s_toolchains" % toolchain.name)
                else:
                    direct_dep_names.append(toolchain.name)
                    direct_dep_names.append("%s_toolchains" % toolchain.name)

    for name, (version, version_file, msys2_packages, ruby_build_version) in registrations.items():
        rb_register_toolchains(
            name = name,
            version = version,
            version_file = version_file,
            msys2_packages = msys2_packages,
            ruby_build_version = ruby_build_version,
            register = False,
        )

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
        "bundle": ruby_bundle,
        "bundle_fetch": ruby_bundle_fetch,
        "toolchain": ruby_toolchain,
    },
)
