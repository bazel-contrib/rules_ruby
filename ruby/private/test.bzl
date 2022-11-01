load("//ruby/private:binary.bzl", "rb_binary_impl")

rb_test = rule(
    implementation = rb_binary_impl,
    test = True,
    attrs = {
        "srcs": attr.label_list(allow_files = True),
        "deps": attr.label_list(),
        "bin": attr.label(
            executable = True,
            allow_single_file = True,
            cfg = "exec",
        ),
        "_windows_constraint": attr.label(
            default = "@platforms//os:windows"
        ),
    },
    toolchains = ["@rules_ruby//:toolchain_type"],
)
