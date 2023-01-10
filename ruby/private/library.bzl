load(
    "//ruby/private:providers.bzl",
    "RubyFiles",
    "get_transitive_data",
    "get_transitive_srcs",
)

ATTRS = {
    "srcs": attr.label_list(
        allow_files = [".rb", ".gemspec", "Gemfile", "Gemfile.lock"],
        doc = "List of Ruby source files used to build the library.",
    ),
    "deps": attr.label_list(
        doc = "List of other Ruby libraries the target depends on.",
    ),
    "data": attr.label_list(
        allow_files = True,
        doc = "List of non-Ruby source files used to build the library.",
    ),
}

def _rb_library_impl(ctx):
    return [
        RubyFiles(
            transitive_data = get_transitive_data(ctx.files.data, ctx.attr.deps),
            transitive_srcs = get_transitive_srcs(ctx.files.srcs, ctx.attr.deps),
        ),
    ]

rb_library = rule(
    implementation = _rb_library_impl,
    attrs = ATTRS,
    doc = """
Defines a Ruby library.

Suppose you have the following Ruby gem:

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

You can define packages for the gem source files:

`BUILD`:
```bazel
load("@rules_ruby//ruby:defs.bzl", "rb_library")

package(default_visibility = ["//:__subpackages__"])

rb_library(
    name = "gem",
    deps = ["//lib:gem"],
)
```

`lib/BUILD`:
```bazel
load("@rules_ruby//ruby:defs.bzl", "rb_library")

package(default_visibility = ["//:__subpackages__"])

rb_library(
    name = "gem",
    srcs = ["gem.rb"],
    deps = [
        "//lib/gem:add",
        "//lib/gem:subtract",
        "//lib/gem:version",
    ],
)
```

`lib/gem/BUILD`:
```bazel
load("@rules_ruby//ruby:defs.bzl", "rb_library")

package(default_visibility = ["//:__subpackages__"])

rb_library(
    name = "add",
    srcs = ["add.rb"],
)

rb_library(
    name = "subtract",
    srcs = ["subtract.rb"],
)

rb_library(
    name = "version",
    srcs = ["version.rb"],
)
```

Once the packages are defined, you can use them in other targets
such as `rb_gem_build()` to build a Ruby gem. See examples of
using other rules.
    """,
)
