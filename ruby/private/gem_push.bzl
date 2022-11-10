load("//ruby/private:binary.bzl", "generate_rb_binary_script")

def _rb_gem_push_impl(ctx):
    script = generate_rb_binary_script(
        ctx,
        ctx.toolchains["@rules_ruby//ruby:toolchain_type"].gem,
        ["push", ctx.file.src.short_path],
    )

    runfiles = ctx.runfiles([ctx.file.src, ctx.toolchains["@rules_ruby//ruby:toolchain_type"].gem])
    return [DefaultInfo(executable = script, runfiles = runfiles)]

rb_gem_push = rule(
    _rb_gem_push_impl,
    executable = True,
    attrs = {
        "src": attr.label(
            allow_single_file = [".gem"],
            mandatory = True,
            doc = """
Gem file to push to RubyGems. You would usually use an output of `rb_gem_build()` target here.
            """,
        ),
        "_windows_constraint": attr.label(
            default = "@platforms//os:windows",
        ),
    },
    toolchains = ["@rules_ruby//ruby:toolchain_type"],
    doc = """
Pushes a built Ruby gem.

Suppose you have the following simple Ruby gem, where `rb_library()` is used
in `BUILD` files to define the packages for the gem and `rb_gem_build()` is used
to build a Ruby gem package from the sources.

```output
|-- BUILD
|-- Gemfile
|-- WORKSPACE
|-- gem.gemspec
`-- lib
    |-- BUILD
    |-- gem
    |   |-- BUILD
    |   |-- add.rb
    |   |-- subtract.rb
    |   `-- version.rb
    `-- gem.rb
```

You can now release the built `.gem` file to RubyGems by defining a target:

`BUILD`:
```bazel
load("@rules_ruby//ruby:defs.bzl", "rb_gem_build", "rb_gem_push", "rb_library")

package(default_visibility = ["//:__subpackages__"])

rb_library(
    name = "gem",
    srcs = [
        "Gemfile",
        "Gemfile.lock",
        "gem.gemspec",
    ],
    deps = ["//lib:gem"],
)

rb_gem_build(
    name = "gem-build",
    gemspec = "gem.gemspec",
    deps = [":gem"],
)

rb_gem_push(
    name = "gem-release",
    src = ":gem-build",
)
```

```output
$ bazel run :gem-release
INFO: Analyzed target //:gem-release (3 packages loaded, 14 targets configured).
INFO: Found 1 target...
Target //:gem-release up-to-date:
  bazel-bin/gem-release.rb.sh
INFO: Elapsed time: 0.113s, Critical Path: 0.01s
INFO: 4 processes: 4 internal.
INFO: Build completed successfully, 4 total actions
INFO: Build completed successfully, 4 total actions
Pushing gem to https://rubygems.org...
Successfully registered gem: example (0.1.0)
```
    """,
)
