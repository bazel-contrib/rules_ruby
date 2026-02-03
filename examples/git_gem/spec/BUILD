load("@rules_ruby//ruby:defs.bzl", "rb_test")

rb_test(
    name = "greeter",
    srcs = ["greeter_spec.rb"],
    args = ["spec/greeter_spec.rb"],
    main = "@bundle//bin:rspec",
    deps = ["@bundle"],
)

rb_test(
    name = "hello_world_bin",
    srcs = ["hello_world_bin_spec.rb"],
    args = ["spec/hello_world_bin_spec.rb"],
    data = ["@bundle//bin:hello_world"],
    env = {"HELLO_WORLD_BIN": "$(rlocationpath @bundle//bin:hello_world)"},
    main = "@bundle//bin:rspec",
    deps = ["@bundle"],
)
