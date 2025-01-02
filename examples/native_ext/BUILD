load("@aspect_bazel_lib//lib:run_binary.bzl", "run_binary")
load("@rules_ruby//ruby:defs.bzl", "rb_gem_build", "rb_gem_install", "rb_library")

package(default_visibility = ["//visibility:public"])

rb_library(
    name = "ext",
    srcs = glob(["ext/**/*.rb"]),
    data = glob([
        "ext/**/*.c",
        "ext/**/*.h",
    ]),
)

rb_library(
    name = "lib",
    srcs = glob(["lib/**/*.rb"]),
)

rb_gem_build(
    name = "native_ext",
    gemspec = "native_ext.gemspec",
    deps = [
        ":ext",
        ":lib",
    ],
)

rb_gem_install(
    name = "install",
    gem = ":native_ext",
)

run_binary(
    name = "compile",
    srcs = [
        "Rakefile",
        "native_ext.gemspec",
        ":ext",
        ":lib",
    ],
    outs = ["tmp/arm64-darwin24/stage/lib/native_ext/native_ext.bundle"],
    # execution_requirements = {"no-sandbox": "0"},
    mnemonic = "RakeCompile",
    # out_dirs = [
    #     "tmp/",
    # ],
    tool = "@bundle//bin:rake",
)
