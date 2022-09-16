load("@rules_ruby//:ruby.bzl", "rb_binary")
load("@rules_ruby//:ruby.bzl", "rb_library")

package(default_visibility = ["//visibility:public"])

# rb_library(
#     name = "rubocop",
#     srcs = glob(["{bundle_path}/ruby/2.7.0/bin/*"]),
#     deps = [":bundle"]
# )

rb_library(
    name = "bundle",
    srcs = glob(["{bundle_path}/**/*"])
)

exports_files(glob(["**/*"]))
