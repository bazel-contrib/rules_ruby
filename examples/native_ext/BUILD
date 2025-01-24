load("@rules_cc//cc:defs.bzl", "cc_library")
load("@rules_java//java:defs.bzl", "java_library")

cc_library(
    name = "ext_c",
    srcs = glob([
        "ext/**/*.c",
        "ext/**/*.h",
    ]),
    target_compatible_with = select({
        "@ruby//engine:ruby": [],
        "//conditions:default": ["@platforms//:incompatible"],
    }),
    deps = ["@ruby//:headers"],
)

java_library(
    name = "ext_java",
    srcs = glob(["ext/**/*.java"]),
    target_compatible_with = select({
        "@ruby//engine:jruby": [],
        "//conditions:default": ["@platforms//:incompatible"],
    }),
    deps = ["@ruby//:jars"],
)
