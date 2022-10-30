load("@rules_ruby//:ruby.bzl", "rb_library")

package(default_visibility = ["//:__subpackages__"])

rb_library(
    name = "gem",
    srcs = ["gem.rb"],
    deps = [
	  "//lib/gem:add",
	  "//lib/gem:subtract",
	  "//lib/gem:version"
    ]
)
