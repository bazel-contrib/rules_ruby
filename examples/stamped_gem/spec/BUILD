load("@rules_ruby//ruby:defs.bzl", "rb_test")
load("//:version.bzl", "UNSTAMPED_VERSION", "VERSION")

rb_test(
    name = "greeter",
    size = "small",
    srcs = ["greeter_spec.rb"],
    args = ["spec/greeter_spec.rb"],
    env = select({
        "//:stamp": {"EXPECTED_VERSION": VERSION},
        "//conditions:default": {"EXPECTED_VERSION": UNSTAMPED_VERSION},
    }),
    main = "@bundle//bin:rspec",
    deps = [
        "//lib:greeter",
        "@bundle",
    ],
)
