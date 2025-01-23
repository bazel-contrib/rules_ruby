load("@rules_java//java:defs.bzl", "java_library")

cc_library(
    name = "ext",
    srcs = glob([
        "ext/**/*.c",
        "ext/**/*.h",
    ]),
    deps = ["@ruby//:headers"],
)

java_library(
    name = "ext_java",
    srcs = glob(["ext/**/*.java"]),
    deps = ["@ruby//:jars"],
)
