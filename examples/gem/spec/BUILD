load("@rules_ruby//ruby:defs.bzl", "rb_library", "rb_test")

package(default_visibility = ["//:__pkg__"])

rb_library(
    name = "spec_helper",
    srcs = ["spec_helper.rb"],
    deps = [
        "//lib:gem",
        "@bundle",
    ],
)

rb_test(
    name = "add",
    size = "small",
    timeout = "moderate",  # JRuby startup can be slow
    srcs = ["add_spec.rb"],
    args = ["spec/add_spec.rb"],
    main = "@bundle//bin:rspec",
    deps = [":spec_helper"],
)

rb_test(
    name = "env",
    size = "small",
    timeout = "moderate",  # JRuby startup can be slow
    srcs = ["env_spec.rb"],
    args = ["spec/env_spec.rb"],
    env = {"EXAMPLE": "ENV"},
    env_inherit = [
        "USER",  # POSIX
        "USERNAME",  # Windows
    ],
    main = "@bundle//bin:rspec",
    deps = [":spec_helper"],
)

rb_test(
    name = "file",
    size = "small",
    timeout = "moderate",  # JRuby startup can be slow
    srcs = ["file_spec.rb"],
    args = ["spec/file_spec.rb"],
    data = ["support/file.txt"],
    main = "@bundle//bin:rspec",
    deps = [":spec_helper"],
)

rb_test(
    name = "subtract",
    size = "small",
    timeout = "moderate",  # JRuby startup can be slow
    srcs = ["subtract_spec.rb"],
    args = ["spec/subtract_spec.rb"],
    main = "@bundle//bin:rspec",
    deps = [":spec_helper"],
)
