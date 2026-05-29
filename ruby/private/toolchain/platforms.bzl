"Shared platform constants for multi-platform Ruby toolchains."

PORTABLE_RUBY_PLATFORMS = [
    "linux_x86_64",
    "linux_arm64",
    "darwin_x86_64",
    "darwin_arm64",
]

JRUBY_PLATFORMS = PORTABLE_RUBY_PLATFORMS + ["windows_x86_64", "windows_arm64"]

PLATFORM_CONSTRAINTS = {
    "linux_x86_64": ["@platforms//os:linux", "@platforms//cpu:x86_64"],
    "linux_arm64": ["@platforms//os:linux", "@platforms//cpu:arm64"],
    "darwin_x86_64": ["@platforms//os:macos", "@platforms//cpu:x86_64"],
    "darwin_arm64": ["@platforms//os:macos", "@platforms//cpu:arm64"],
    "windows_x86_64": ["@platforms//os:windows", "@platforms//cpu:x86_64"],
    "windows_arm64": ["@platforms//os:windows", "@platforms//cpu:arm64"],
}

# Mapping from canonical platform key to portable-ruby artifact suffix.
PORTABLE_RUBY_ARTIFACT_KEY = {
    "linux_x86_64": "x86_64_linux",
    "linux_arm64": "arm64_linux",
    "darwin_x86_64": "x86_64_darwin",
    "darwin_arm64": "arm64_darwin",
}

def engine_from_version(version):
    """Infer the Ruby engine (`ruby`, `jruby`, `truffleruby`) from a version string.

    Args:
        version: Version string such as `3.4.8`, `jruby-10.1.0.0`, or
            `truffleruby-24.0.0`. May be None, in which case `ruby` is returned.

    Returns:
        One of `ruby`, `jruby`, `truffleruby`.
    """
    if version and version.startswith("jruby"):
        return "jruby"
    if version and version.startswith("truffleruby"):
        return "truffleruby"
    return "ruby"
