load("//ruby/private:binary.bzl", "ATTRS", "rb_binary_impl")
load("//ruby/private:library.bzl", LIBRARY_ATTRS = "ATTRS")

rb_test = rule(
    implementation = rb_binary_impl,
    executable = True,
    test = True,
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
    main = "@bundle//:bin/rspec",
    deps = [
        ":spec_helper",
        "//:gem",
        "@bundle",
    ],
)

rb_test(
    name = "subtract",
    srcs = ["subtract_spec.rb"],
    args = ["spec/subtract_spec.rb"],
    main = "@bundle//:bin/rspec",
    deps = [
        ":spec_helper",
        "//:gem",
        "@bundle",
    ],
)
```

```output
$ bazel test spec/...
INFO: Analyzed 3 targets (22 packages loaded, 621 targets configured).
INFO: Found 1 target and 2 test targets...
INFO: Elapsed time: 2.354s, Critical Path: 0.49s
INFO: 9 processes: 5 internal, 4 darwin-sandbox.
INFO: Build completed successfully, 9 total actions
//spec:add                                                               PASSED in 0.4s
//spec:subtract                                                          PASSED in 0.4s

Executed 2 out of 2 tests: 2 tests pass.
```

Since `rb_test()` is a wrapper around `rb_binary()`, you can also use it to run
a Ruby binary script available in Gemfile dependencies, by passing `main`
argument with a path to a Bundler binary stub.

`BUILD`:
```bazel
load("@rules_ruby//ruby:defs.bzl", "rb_library", "rb_test")

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

rb_test(
    name = "rubocop",
    args = ["lib/"],
    main = "@bundle//:bin/rubocop",
    tags = ["no-sandbox"],
    deps = [
        ":gem",
        "@bundle",
    ],
)
```

```output
$ bazel test :rubocop
INFO: Analyzed target //:rubocop (0 packages loaded, 123 targets configured).
INFO: Found 1 test target...
Target //:rubocop up-to-date:
  bazel-bin/rubocop.rb.sh
INFO: Elapsed time: 0.875s, Critical Path: 0.79s
INFO: 2 processes: 2 local.
INFO: Build completed successfully, 2 total actions
//:rubocop                                                               PASSED in 0.8s

Executed 1 out of 1 test: 1 test passes.
```

Note that you can also `run` every test target passing extra arguments to
the Ruby script. For example, you can re-use `:rubocop` target to perform autocorrect:

```output
$ bazel run :rubocop -- --autocorrect-all
INFO: Analyzed target //:rubocop (0 packages loaded, 0 targets configured).
INFO: Found 1 target...
Target //:rubocop up-to-date:
  bazel-bin/rubocop.rb.sh
INFO: Elapsed time: 0.066s, Critical Path: 0.00s
INFO: 1 process: 1 internal.
INFO: Build completed successfully, 1 total action
INFO: Running command line: external/bazel_tools/tools/test/test-setup.sh ./rubocop.rb.sh --autocorrect-all
exec ${PAGER:-/usr/bin/less} "$0" || exit 1
Executing tests from //:rubocop
-----------------------------------------------------------------------------
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
