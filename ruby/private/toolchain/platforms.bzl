"Shared platform constants for multi-platform Ruby toolchains."

# Canonical platform keys use the `{arch}_{os}` order to match the naming used
# by portable-ruby's release artifacts (e.g. `ruby-X.Y.Z.x86_64_linux.tar.gz`),
# avoiding any conversion when constructing the download URL.
#
# The Windows entries are NOT covered by portable-ruby (which only ships
# Linux/Darwin tarballs). They exist here so multi-platform mode also
# registers Windows-constrained toolchains; `_rb_download_impl` then routes
# Windows downloads to RubyInstaller instead of the portable-ruby URL.
PORTABLE_RUBY_PLATFORMS = [
    "arm64_darwin",
    "arm64_linux",
    "x86_64_darwin",
    "x86_64_linux",
]

WINDOWS_RUBY_PLATFORMS = [
    "arm64_windows",
    "x86_64_windows",
]

MULTI_PLATFORM_RUBY_PLATFORMS = PORTABLE_RUBY_PLATFORMS + WINDOWS_RUBY_PLATFORMS

PLATFORM_CONSTRAINTS = {
    "arm64_darwin": ["@platforms//os:macos", "@platforms//cpu:arm64"],
    "arm64_linux": ["@platforms//os:linux", "@platforms//cpu:arm64"],
    "arm64_windows": ["@platforms//os:windows", "@platforms//cpu:arm64"],
    "x86_64_darwin": ["@platforms//os:macos", "@platforms//cpu:x86_64"],
    "x86_64_linux": ["@platforms//os:linux", "@platforms//cpu:x86_64"],
    "x86_64_windows": ["@platforms//os:windows", "@platforms//cpu:x86_64"],
}
