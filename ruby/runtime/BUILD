load("//ruby/private:library.bzl", "rb_library_wo_toolchains")

rb_library_wo_toolchains(
    name = "setup",
    srcs = ["setup.rb"],
    visibility = ["//visibility:public"],
    deps = [
        ":bazel_patches",
        ":bytecode_loader",
    ],
)

rb_library_wo_toolchains(
    name = "bazel_patches",
    srcs = ["bazel_patches.rb"],
    visibility = ["//visibility:public"],
)

rb_library_wo_toolchains(
    name = "bytecode_loader",
    srcs = ["bytecode_loader.rb"],
    visibility = ["//visibility:public"],
)
