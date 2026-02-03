load("@rules_ruby//ruby:defs.bzl", "rb_binary", "rb_test")

rb_binary(
    name = "greeter",
    srcs = ["greeter.rb"],
    deps = ["@bundle"],
)

rb_test(
    name = "greeter_test",
    srcs = ["greeter_test.rb"],
    deps = ["@bundle"],
)

rb_test(
    name = "hello_world_bin_test",
    srcs = ["hello_world_bin_test.rb"],
    args = ["$(rlocationpath @bundle//bin:hello_world)"],
    data = ["@bundle//bin:hello_world"],
    main = "hello_world_bin_test.rb",
)
