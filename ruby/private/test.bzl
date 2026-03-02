"Implementation details for rb_test"

load("//ruby/private:binary.bzl", "ATTRS", "rb_binary_impl")
load("//ruby/private:library.bzl", LIBRARY_ATTRS = "ATTRS")

rb_test = rule(
    implementation = rb_binary_impl,
    executable = True,
    test = True,
    fragments = ["coverage"],
    attrs = dict(
        ATTRS,
        srcs = LIBRARY_ATTRS["srcs"],
        data = LIBRARY_ATTRS["data"],
        deps = LIBRARY_ATTRS["deps"],
    ),
    toolchains = [
        "@rules_ruby//ruby:toolchain_type",
        "@bazel_tools//tools/jdk:runtime_toolchain_type",
    ],
    doc = """
Runs a Ruby test.

Suppose you have the following Ruby gem, where `rb_library()` is used
in `BUILD` files to define the packages for the gem.

```output
|-- BUILD
|-- Gemfile
|-- WORKSPACE
|-- gem.gemspec
|-- lib
|   |-- BUILD
|   |-- gem
|   |   |-- BUILD
|   |   |-- add.rb
|   |   |-- subtract.rb
|   |   `-- version.rb
|   `-- gem.rb
`-- spec
    |-- BUILD
    |-- add_spec.rb
    |-- spec_helper.rb
    `-- subtract_spec.rb
```

You can run all tests inside `spec/` by defining individual targets:

`spec/BUILD`:
```bazel
load("@rules_ruby//ruby:defs.bzl", "rb_library", "rb_test")

rb_library(
    name = "spec_helper",
    srcs = ["spec_helper.rb"],
)

rb_test(
    name = "add",
    srcs = ["add_spec.rb"],
    args = ["spec/add_spec.rb"],
    main = "@bundle//bin:rspec",
    deps = [
        ":spec_helper",
        "@bundle",
    ],
)

rb_test(
    name = "subtract",
    srcs = ["subtract_spec.rb"],
    args = ["spec/subtract_spec.rb"],
    main = "@bundle//bin:rspec",
    deps = [
        ":spec_helper",
        "@bundle",
    ],
)
```

```output
$ bazel test spec/...
...
//spec:add                                                               PASSED in 0.4s
//spec:subtract                                                          PASSED in 0.4s

Executed 2 out of 2 tests: 2 tests pass.
```

Since `rb_test()` is a wrapper around `rb_binary()`, you can also use it to run
a Ruby binary script available in Gemfile dependencies, by passing `main`
argument with a path to a Bundler binary stub.

`BUILD`:
```bazel
load("@rules_ruby//ruby:defs.bzl", "rb_test")

package(default_visibility = ["//:__subpackages__"])

rb_test(
    name = "rubocop",
    args = ["lib/"],
    main = "@bundle//bin:rubocop",
    tags = ["no-sandbox"],
    deps = [
        "//lib:gem",
        "@bundle",
    ],
)
```

```output
$ bazel test :rubocop
...
//:rubocop                                                               PASSED in 0.8s

Executed 1 out of 1 test: 1 test passes.
```

### Code Coverage

To enable code coverage, run tests with the `coverage` command:

```bash
bazel coverage //...
```

See the [README](../../README.md#code-coverage) for more details.

Note that you can also `run` every test target passing extra arguments to
the Ruby script. For example, you can re-use `:rubocop` target to perform autocorrect:

```output
$ bazel run :rubocop -- --autocorrect-all
...
Inspecting 11 files
.C.........

Offenses:

gem.gemspec:1:1: C: [Corrected] Style/FrozenStringLiteralComment: Missing frozen string literal comment.
root = File.expand_path(__dir__)
^
gem.gemspec:2:1: C: [Corrected] Layout/EmptyLineAfterMagicComment: Add an empty line after magic comments.
root = File.expand_path(__dir__)
^

11 files inspected, 2 offenses detected, 2 offenses corrected
```
    """,
)
