"Module extensions used by bzlmod"

load("//ruby/private:download.bzl", "DEFAULT_RUBY_REPOSITORY")
load(":deps.bzl", "rb_bundle", "rb_register_toolchains")

ruby_bundle = tag_class(attrs = {
    "name": attr.string(doc = "Resulting repository name for the bundle"),
    "srcs": attr.label_list(),
    "env": attr.string_dict(),
    "gemfile": attr.label(),
    "toolchain": attr.label(),
})

ruby_toolchain = tag_class(attrs = {
    "name": attr.string(doc = "Base name for generated repositories, allowing multiple to be registered."),
    "version": attr.string(doc = "Explicit version of ruby."),
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

        for toolchain in mod.tags.toolchain:
            # Prevent a users dependencies creating conflicting toolchain names
            if toolchain.name != DEFAULT_RUBY_REPOSITORY and not mod.is_root:
                fail("Only the root module may provide a name for the ruby toolchain.")

            if toolchain.name in registrations.keys():
                if toolchain.version == registrations[toolchain.name]:
                    # No problem to register a matching toolchain twice
                    continue
                fail("Multiple conflicting toolchains declared for name {} ({} and {}".format(
                    toolchain.name,
                    toolchain.version,
                    registrations[toolchain.name],
                ))
            else:
                registrations[toolchain.name] = toolchain.version

    for name, version in registrations.items():
        rb_register_toolchains(
            name = name,
            version = version,
            register = False,
        )

ruby = module_extension(
    implementation = _ruby_module_extension,
    tag_classes = {
        "bundle": ruby_bundle,
        "toolchain": ruby_toolchain,
    },
)
