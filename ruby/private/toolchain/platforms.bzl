"Shared platform constants for multi-platform Ruby toolchains."

PORTABLE_RUBY_PLATFORMS = [
    "linux_x86_64",
    "linux_arm64",
    "darwin_x86_64",
    "darwin_arm64",
]

PLATFORM_CONSTRAINTS = {
    "linux_x86_64": ["@platforms//os:linux", "@platforms//cpu:x86_64"],
    "linux_arm64": ["@platforms//os:linux", "@platforms//cpu:arm64"],
    "darwin_x86_64": ["@platforms//os:macos", "@platforms//cpu:x86_64"],
    "darwin_arm64": ["@platforms//os:macos", "@platforms//cpu:arm64"],
}

# Mapping from canonical platform key to portable-ruby artifact suffix.
PORTABLE_RUBY_ARTIFACT_KEY = {
    "linux_x86_64": "x86_64_linux",
    "linux_arm64": "arm64_linux",
    "darwin_x86_64": "x86_64_darwin",
    "darwin_arm64": "arm64_darwin",
}
