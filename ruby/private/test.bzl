load("//ruby/private:binary.bzl", "COMMON_ATTRS", "rb_binary_impl")

rb_test = rule(
    implementation = rb_binary_impl,
    executable = True,
    test = True,
    attrs = dict(COMMON_ATTRS),
    toolchains = ["@rules_ruby//ruby:toolchain_type"],
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
    """,
)
