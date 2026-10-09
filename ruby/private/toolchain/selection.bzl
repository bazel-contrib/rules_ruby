"""Select Ruby toolchains, allowing root modules to override the fallback."""

_TOOLCHAIN_ATTRIBUTES = [
    "version",
    "version_file",
    "msys2_packages",
    "ruby_build_version",
    "portable_ruby",
    "portable_ruby_release_suffix",
    "portable_ruby_checksums",
]

def select_toolchains(modules):
    """Return toolchain configurations, with root declarations taking precedence.

    Args:
        modules: Module extension's participating modules, in breadth-first order.

    Returns:
        A dict mapping repository names to toolchain attribute dicts.
    """
    registrations = {}
    root_names = {}

    # The ruleset's built-in toolchain is a fallback even when rules_ruby appears
    # before another dependency in the module graph.
    ordered = [mod for mod in modules if mod.is_root]
    ordered += [mod for mod in modules if not mod.is_root and mod.name != "rules_ruby"]
    ordered += [mod for mod in modules if not mod.is_root and mod.name == "rules_ruby"]
    for mod in ordered:
        for toolchain in mod.tags.toolchain:
            name = toolchain.name
            if name != "ruby" and not mod.is_root:
                fail("Only the root module may provide a name for the ruby toolchain.")
            if not mod.is_root and (name in root_names or (mod.name == "rules_ruby" and name in registrations)):
                continue
            config = {attr: getattr(toolchain, attr) for attr in _TOOLCHAIN_ATTRIBUTES}
            if name in registrations and config != registrations[name]:
                fail("Multiple conflicting toolchains declared for name {}: {} and {}".format(
                    name,
                    registrations[name],
                    config,
                ))
            registrations[name] = config
            if mod.is_root:
                root_names[name] = True
    return registrations
