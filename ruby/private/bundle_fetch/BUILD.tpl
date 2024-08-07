"""@generated by @rules_ruby//:ruby/private/bundle_fetch.bzl"""

load("@rules_ruby//ruby:defs.bzl", "rb_bundle_install", "rb_gem", "rb_gem_install")

package(default_visibility = ["//visibility:public"])

rb_bundle_install(
    name = "{name}",
    srcs = {srcs},
    env = {env},
    gemfile = "{gemfile_path}",
    gemfile_lock = "{gemfile_lock_path}",
    gems = {gems},
    ruby = {ruby},
)

{gem_fragments}

{gem_install_fragments}

# vim: ft=bzl
