load("@rules_ruby//ruby:defs.bzl", "rb_binary", "rb_test")

rb_binary(
    name = "app",
    srcs = ["hello.rb"],
    main = "hello.rb",
    deps = [
        "//proto:foo_proto",
        "@bundle",
    ],
)

rb_test(
    name = "hello_test",
    srcs = ["hello_test.rb"],
    main = "hello_test.rb",
    deps = [
        "//proto:foo_proto",
        "@bundle",
    ],
)
