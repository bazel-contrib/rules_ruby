load("@rules_ruby//ruby:defs.bzl", "rb_binary")

rb_binary(
    name = "app",
    srcs = ["hello.rb"],
    main = "hello.rb",
    deps = [
        "//proto:foo_proto",
        "@bundle",
    ],
)
