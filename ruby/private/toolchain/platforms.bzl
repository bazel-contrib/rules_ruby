"Shared platform constants for multi-platform Ruby toolchains."

# Canonical platform keys use the `{arch}_{os}` order to match the naming used
# by portable-ruby's release artifacts (e.g. `ruby-X.Y.Z.x86_64_linux.tar.gz`),
# avoiding any conversion when constructing the download URL.
PORTABLE_RUBY_PLATFORMS = [
    "arm64_darwin",
    "arm64_linux",
    "x86_64_darwin",
    "x86_64_linux",
]

PLATFORM_CONSTRAINTS = {
    "arm64_darwin": ["@platforms//os:macos", "@platforms//cpu:arm64"],
    "arm64_linux": ["@platforms//os:linux", "@platforms//cpu:arm64"],
    "x86_64_darwin": ["@platforms//os:macos", "@platforms//cpu:x86_64"],
    "x86_64_linux": ["@platforms//os:linux", "@platforms//cpu:x86_64"],
}
