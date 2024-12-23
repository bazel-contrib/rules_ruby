load("@bazel_skylib//rules:common_settings.bzl", "string_flag")

package(default_visibility = ["//visibility:public"])

string_flag(
    name = "engine",
    values = [
        "jruby",
        "truffleruby",
        "ruby",
    ],
    build_setting_default = "{ruby_engine}",
)

config_setting(
    name = "jruby",
    flag_values = {
        ":engine": "jruby",
    },
)

config_setting(
    name = "truffleruby",
    flag_values = {
        ":engine": "truffleruby",
    },
)

config_setting(
    name = "ruby",
    flag_values = {
        ":engine": "ruby",
    },
)

# vim: ft=bzl
