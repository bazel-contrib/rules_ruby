load("@aspect_bazel_lib//lib:run_binary.bzl", "run_binary")
load("@bazel_skylib//rules:write_file.bzl", "write_file")

package(default_visibility = ["//visibility:public"])

filegroup(
    name = "sources",
    srcs = glob(
        [
            "_posts/**/*",
            "_layouts/**/*",
        ],
        allow_empty = True,
    ) + [
        "404.html",
        "about.md",
        "index.md",
    ],
)

run_binary(
    name = "site_build",
    srcs = [
        ":_config.yml",
        ":sources",
    ],
    args = [
        "build",
        "--destination",
        "$(GENDIR)/_site",
        "--config",
        "$(location :_config.yml)",
    ],
    env = {
        "LC_ALL": "C.UTF-8",
        "LANG": "en_US.UTF-8",
        "LANGUAGE": "en_US.UTF-8",
    },
    execution_requirements = {"no-sandbox": "1"},
    mnemonic = "JekyllBuild",
    out_dirs = [
        "_site",
    ],
    tool = "@bundle//bin:jekyll",
)

write_file(
    name = "site_serve_file",
    out = "site_serve_file.sh",
    content = [
        "#!/bin/bash",
        # rules_ruby needs RUNFILES_DIR to be set
        "export RUNFILES_DIR=$(readlink -f ../)",
        "EXEC_ROOT=$(pwd)",
        "$EXEC_ROOT/$1 ${@:2}",
    ],
)

sh_binary(
    name = "site_serve",
    srcs = [
        ":site_serve_file",
    ],
    args = [
        "$(location @bundle//bin:jekyll)",
        "serve",
        "--destination",
        "_site",
        "--skip-initial-build",
        "--config",
        "$(location :_config.yml)",
    ],
    data = [
        ":_config.yml",
        ":site_build",
        "@bundle//bin:jekyll",
    ],
)
