load("@rules_ruby//:ruby.bzl", "rb_binary")
load("@rules_ruby//:ruby.bzl", "rb_library")

package(default_visibility = ["//:__subpackages__"])

rb_library(
    name = "gem",
    deps = ["//lib:gem"]
)

rb_binary(
    name = "rubocop",
    bin = "@bundle//:vendor/bundle/ruby/2.7.0/bin/rubocop",
    deps = [
	":gem",
	"@bundle"
    ],
)

# rb_library(
#     name = "spec",
#     bin = "@bundle//:rspec-r",
#     deps = [
# 	":gem",
# 	"@bundle"
#     ],
# )
