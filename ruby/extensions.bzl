"Module extensions used by bzlmod"

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
})

ruby_toolchain = tag_class(attrs = {
    "name": attr.string(doc = "Base name for generated repositories, allowing multiple to be registered."),
    "version": attr.string(doc = "Explicit version of ruby."),
    "version_file": attr.label(doc = "File to read Ruby version from."),
    "msys2_packages": attr.string_list(doc = "Extra MSYS2 packages to install.", default = ["libyaml"]),
})

def _ruby_module_extension(module_ctx):
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

        for bundle_fetch in mod.tags.bundle_fetch:
            rb_bundle_fetch(
                name = bundle_fetch.name,
                srcs = bundle_fetch.srcs,
                env = bundle_fetch.env,
                gemfile = bundle_fetch.gemfile,
                gemfile_lock = bundle_fetch.gemfile_lock,
            )

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
                    registrations[toolchain.name],
                ))
            else:
                registrations[toolchain.name] = (toolchain.version, toolchain.version_file, toolchain.msys2_packages)

    for name, (version, version_file, msys2_packages) in registrations.items():
        rb_register_toolchains(
            name = name,
            version = version,
            version_file = version_file,
            msys2_packages = msys2_packages,
            register = False,
        )

ruby = module_extension(
    implementation = _ruby_module_extension,
    tag_classes = {
        "bundle": ruby_bundle,
        "bundle_fetch": ruby_bundle_fetch,
        "toolchain": ruby_toolchain,
    },
)
