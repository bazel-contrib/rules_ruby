"Implementation details for rb_library"

load(
    "//ruby/private:providers.bzl",
    "BundlerInfo",
    "RubyFilesInfo",
    "get_bundle_env",
    "get_transitive_data",
    "get_transitive_deps",
    "get_transitive_runfiles",
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
        doc = "List of runtime dependencies needed by a program that depends on this library.",
    ),
    "bundle_env": attr.string_dict(
        default = {},
        doc = "List of bundle environment variables to set when building the library.",
    ),
}

def _rb_library_impl(ctx):
    # TODO: avoid expanding the depset to a list, it may be expensive in a large graph
    transitive_data = get_transitive_data(ctx.files.data, ctx.attr.deps).to_list()
    transitive_deps = get_transitive_deps(ctx.attr.deps).to_list()
    transitive_srcs = get_transitive_srcs(ctx.files.srcs, ctx.attr.deps).to_list()

    runfiles = ctx.runfiles(transitive_srcs + transitive_data)
    runfiles = get_transitive_runfiles(runfiles, ctx.attr.srcs, ctx.attr.deps, ctx.attr.data)

    providers = [
        DefaultInfo(
            files = depset(transitive_srcs + transitive_data),
            runfiles = runfiles,
        ),
        RubyFilesInfo(
            transitive_data = depset(transitive_data),
            transitive_deps = depset(transitive_deps),
            transitive_srcs = depset(transitive_srcs),
            bundle_env = get_bundle_env(ctx.attr.bundle_env, ctx.attr.deps),
        ),
    ]

    for dep in transitive_deps:
        if BundlerInfo in dep:
            providers.append(dep[BundlerInfo])
            break

    return providers

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
