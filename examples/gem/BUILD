load("@aspect_bazel_lib//lib:expand_template.bzl", "expand_template")
load("@aspect_bazel_lib//lib:paths.bzl", "BASH_RLOCATION_FUNCTION")
load(
    "@rules_ruby//ruby:defs.bzl",
    "rb_binary",
    "rb_gem_build",
    "rb_gem_install",
    "rb_gem_push",
    "rb_test",
)
load("@rules_shell//shell:sh_test.bzl", "sh_test")

package(default_visibility = ["//:__subpackages__"])

expand_template(
    name = "shell_wrapper",
    out = "wrapper.sh",
    data = [
        ":Rakefile",
        ":rake",
    ],
    substitutions = {
        "@@rlocation_lib@@": BASH_RLOCATION_FUNCTION.replace("$", "$$"),
        "@@rake_binary@@": "$(rlocationpaths :rake)",
        "@@rakefile@@": "$(rlocationpaths :Rakefile)",
    },
    template = "wrapper.tpl.sh",
)

sh_test(
    name = "shell_wrapper_test",
    srcs = [":shell_wrapper"],
    data = [
        ":Rakefile",
        ":rake",
    ],
    tags = ["bcr-presubmit-failure"],
    deps = ["@bazel_tools//tools/bash/runfiles"],
)

rb_binary(
    name = "rake",
    main = "@bundle//bin:rake",
    deps = [
        "//lib:gem",
        "@bundle",
    ],
)

rb_test(
    name = "rubocop",
    size = "small",
    timeout = "moderate",  # JRuby startup can be slow
    data = [".rubocop.yml"],
    main = "@bundle//bin:rubocop",
    tags = ["no-sandbox"],
    deps = [
        "//lib:gem",
        "//spec:add",
        "//spec:env",
        "//spec:subtract",
        "//spec:support",
        "@bundle",
    ],
)

rb_gem_build(
    name = "gem-build",
    gemspec = "gem.gemspec",
    deps = ["//lib:gem"],
)

rb_gem_install(
    name = "gem-install",
    gem = ":gem-build",
)

rb_gem_push(
    name = "gem-release",
    gem = ":gem-build",
)
